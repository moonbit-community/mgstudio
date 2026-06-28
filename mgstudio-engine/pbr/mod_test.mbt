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
fn read_pbr_runtime_config(world : @ecs.World) -> PbrPluginRuntimeConfig {
  match world.get_resource(ecs_key_pbr_plugin_runtime_config) {
    Some(config) => config
    None => abort("missing PbrPluginRuntimeConfig resource")
  }
}

///|
fn read_deferred_lighting_state(world : @ecs.World) -> DeferredPbrLightingState {
  match world.get_resource(ecs_key_deferred_pbr_lighting_state) {
    Some(state) => state
    None => abort("missing DeferredPbrLightingState resource")
  }
}

///|
fn read_standard_material_plugin_state(
  world : @ecs.World,
) -> StandardMaterialPluginState {
  match world.get_resource(ecs_key_standard_material_plugin_state) {
    Some(state) => state
    None => abort("missing StandardMaterialPluginState resource")
  }
}

///|
fn read_mesh_render_plugin_state(world : @ecs.World) -> MeshRenderPluginState {
  match world.get_resource(ecs_key_mesh_render_plugin_state) {
    Some(state) => state
    None => abort("missing MeshRenderPluginState resource")
  }
}

///|
fn read_materials_plugin_state(world : @ecs.World) -> MaterialsPluginState {
  match world.get_resource(ecs_key_materials_plugin_state) {
    Some(state) => state
    None => abort("missing MaterialsPluginState resource")
  }
}

///|
fn read_any_prepass_plugin_loaded(
  world : @ecs.World,
) -> @pbr_prepass.AnyPrepassPluginLoaded {
  match world.get_resource(@pbr_prepass.ecs_key_any_prepass_plugin_loaded) {
    Some(state) => state
    None => abort("missing AnyPrepassPluginLoaded resource")
  }
}

///|
fn read_gpu_preprocess_state(
  world : @ecs.World,
) -> @pbr_render.Render3dGpuPreprocessState {
  match world.get_resource(@pbr_render.Render3dGpuPreprocessState::resource()) {
    Some(state) => state
    None => abort("missing Render3dGpuPreprocessState resource")
  }
}

///|
fn read_default_standard_material(
  world : @ecs.World,
) -> @material.StandardMaterial {
  let key : @ecs.ResourceKey[@asset.Assets[@material.StandardMaterial]] = @asset.assets_resource_key()
  guard world.get_resource(key) is Some(assets) else {
    abort("missing StandardMaterial assets resource")
  }
  guard assets.get(@asset.Handle::new(0)) is Some(material) else {
    abort("missing default StandardMaterial handle")
  }
  material
}

///|
test "pbr: MeshRenderPlugin registers Bevy-shaped render system order" {
  let app = @app.App::new(@ecs.World::new())
    .add_plugins(@asset.AssetPlugin::AssetPlugin())
    .add_plugins(@shader.ShaderPlugin::ShaderPlugin())
    .add_plugins(@render.RenderPlugin::RenderPlugin())
    .add_plugins(PbrPlugin::PbrPlugin())
  let sub_app = app.sub_app(@app.RenderApp)
  let settings = @app.ScheduleGraphSettings::ScheduleGraphSettings().with_include_system_name(fn(
      name : String,
    ) {
      name.has_prefix("pbr.render3d.")
    },
  )
  let render_dot = sub_app.schedule_graph_dot(
    @render.render_schedule_stage(),
    settings~,
  )
  debug_inspect(render_dot.contains("\"pbr.render3d.extract\""), content="true")
  debug_inspect(
    render_dot.contains("\"pbr.render3d.prepare_morphs\""),
    content="true",
  )
  debug_inspect(
    render_dot.contains("\"pbr.render3d.prepare_skin_bindings\""),
    content="true",
  )
  debug_inspect(
    render_dot.contains("\"pbr.render3d.prepare_fog\""),
    content="true",
  )
  debug_inspect(
    render_dot.contains("\"pbr.render3d.prepare_resources_cleanup\""),
    content="true",
  )
  debug_inspect(
    render_dot.contains("\"pbr.render3d.prepare_resources_flush\""),
    content="true",
  )
  debug_inspect(
    render_dot.contains("\"pbr.render3d.prepare_meshes\""),
    content="true",
  )
  debug_inspect(
    render_dot.contains("\"pbr.render3d.specialize_material_meshes\""),
    content="true",
  )
  debug_inspect(
    render_dot.contains("\"pbr.render3d.prepare_bind_groups\""),
    content="true",
  )
  debug_inspect(
    render_dot.contains("\"pbr.render3d.queue_meshes\""),
    content="true",
  )
  debug_inspect(
    render_dot.contains("\"pbr.render3d.queue_shadows\""),
    content="true",
  )
  debug_inspect(
    render_dot.contains("\"pbr.render3d.queue_sweep\""),
    content="true",
  )
  debug_inspect(
    render_dot.contains(
      "\"pbr.render3d.extract\" -> \"pbr.render3d.prepare_meshes\"",
    ),
    content="true",
  )
  debug_inspect(
    render_dot.contains(
      "\"pbr.render3d.prepare_meshes\" -> \"pbr.render3d.specialize_material_meshes\"",
    ),
    content="true",
  )
  debug_inspect(
    render_dot.contains(
      "\"pbr.render3d.specialize_material_meshes\" -> \"pbr.render3d.queue_meshes\"",
    ),
    content="true",
  )
  debug_inspect(
    render_dot.contains(
      "\"pbr.render3d.queue_meshes\" -> \"pbr.render3d.queue_shadows\"",
    ),
    content="true",
  )
  debug_inspect(
    render_dot.contains(
      "\"pbr.render3d.queue_shadows\" -> \"pbr.render3d.queue_sweep\"",
    ),
    content="true",
  )
  debug_inspect(
    render_dot.contains(
      "\"pbr.render3d.prepare_resources_cleanup\" -> \"pbr.render3d.prepare_morphs\"",
    ),
    content="true",
  )
  debug_inspect(
    render_dot.contains(
      "\"pbr.render3d.prepare_morphs\" -> \"pbr.render3d.prepare_resources_flush\"",
    ),
    content="true",
  )
  debug_inspect(
    render_dot.contains(
      "\"pbr.render3d.prepare_resources_flush\" -> \"pbr.render3d.prepare_bind_groups\"",
    ),
    content="true",
  )
  let graph_dot = sub_app.schedule_graph_dot(
    @render.RenderGraph::schedule(),
    settings~,
  )
  debug_inspect(graph_dot.contains("\"pbr.render3d.execute\""), content="true")
  let pbr_plugin_settings = @app.ScheduleGraphSettings::ScheduleGraphSettings().with_include_system_name(fn(
      name : String,
    ) {
      name.has_prefix("mgstudio_pbr::")
    },
  )
  let pbr_plugin_render_dot = sub_app.schedule_graph_dot(
    @render.render_schedule_stage(),
    settings=pbr_plugin_settings,
  )
  debug_inspect(
    pbr_plugin_render_dot.contains(
      "\"mgstudio_pbr::extract_clusters_for_cpu_clustering\"",
    ),
    content="true",
  )
  debug_inspect(
    pbr_plugin_render_dot.contains(
      "\"mgstudio_pbr::gather_environment_map_light_probes\"",
    ),
    content="true",
  )
  debug_inspect(
    pbr_plugin_render_dot.contains(
      "\"mgstudio_pbr::gather_irradiance_volume_light_probes\"",
    ),
    content="true",
  )
  debug_inspect(
    pbr_plugin_render_dot.contains(
      "\"mgstudio_pbr::gather_environment_map_light_probes\" -> \"mgstudio_pbr::gather_irradiance_volume_light_probes\"",
    ),
    content="true",
  )
  debug_inspect(
    pbr_plugin_render_dot.contains(
      "\"mgstudio_pbr::gather_irradiance_volume_light_probes\" -> \"mgstudio_pbr::extract_clusters_for_cpu_clustering\"",
    ),
    content="true",
  )
  debug_inspect(
    pbr_plugin_render_dot.contains(
      "\"mgstudio_pbr::prepare_clusters_for_cpu_clustering\"",
    ),
    content="true",
  )
  debug_inspect(
    pbr_plugin_render_dot.contains(
      "\"mgstudio_pbr::prepare_shadow_phase_buffers\"",
    ),
    content="true",
  )
  debug_inspect(
    pbr_plugin_render_dot.contains(
      "\"mgstudio_pbr::collect_shadow_phase_buffers\"",
    ),
    content="true",
  )
  debug_inspect(
    pbr_plugin_render_dot.contains(
      "\"mgstudio_pbr::prepare_shadow_phase_buffers\" -> \"mgstudio_pbr::collect_shadow_phase_buffers\"",
    ),
    content="true",
  )
  debug_inspect(
    pbr_plugin_render_dot.contains(
      "\"mgstudio_pbr::extract_clusters_for_gpu_clustering\"",
    ),
    content="true",
  )
}

///|
struct PrepareLightsScheduleProbe {
  mut spawned_view : @core.Entity?
}

///|
let prepare_lights_schedule_probe_key : @ecs.ResourceKey[
  PrepareLightsScheduleProbe,
] = @ecs.register_resource(
  debug_name="mgstudio_pbr.test.prepare_lights_schedule_probe",
)

///|
fn prepare_lights_schedule_spawn_view(world : @ecs.World) -> Unit {
  world.insert_resource(
    @light_cluster.GlobalClusterSettings::resource(),
    @light_cluster.GlobalClusterSettings::new(true, true, None, 204, 16384),
  )
  match world.get_resource(prepare_lights_schedule_probe_key) {
    Some(probe) =>
      if probe.spawned_view is None {
        let view = world.spawn()
        try! world.set_by_key(
          view,
          @render_view.ExtractedView::component(),
          @render_view.ExtractedView::new(
            @render_view.RetainedViewEntity::new(view),
          ),
        )
        try! world.set_by_key(view, ecs_key_camera3d, Camera3d::Camera3d())
        probe.spawned_view = Some(view)
      }
    None => ()
  }
}

///|
struct PrepareClusteredDecalsScheduleProbe {
  mut decal_entity : @core.Entity?
  mut light_texture_entity : @core.Entity?
}

///|
let prepare_clustered_decals_schedule_probe_key : @ecs.ResourceKey[
  PrepareClusteredDecalsScheduleProbe,
] = @ecs.register_resource(
  debug_name="mgstudio_pbr.test.prepare_clustered_decals_schedule_probe",
)

///|
fn prepare_clustered_decals_schedule_seed(world : @ecs.World) -> Unit {
  world.insert_resource(
    @light_cluster.GlobalClusterSettings::resource(),
    @light_cluster.GlobalClusterSettings::new(true, true, None, 204, 16384),
  )
  let view = world.spawn()
  try! world.set_by_key(
    view,
    @render_view.ExtractedView::component(),
    @render_view.ExtractedView::new(@render_view.RetainedViewEntity::new(view)),
  )
  try! world.set_by_key(view, ecs_key_camera3d, Camera3d::Camera3d())
  let decal_entity = world.spawn()
  let decal = @light.ClusteredDecal::ClusteredDecal().with_tag(3U)
  try! world.set_by_key(decal_entity, @pbr_decal.ecs_key_clustered_decal, decal)
  let light_texture_entity = world.spawn()
  let render_decals_ref = @pbr_decal.render3d_render_clustered_decals_ref_or_init(
    world,
  )
  render_decals_ref.modify(fn(render_decals) {
    ignore(render_decals.insert_decal(decal_entity, decal))
    ignore(
      render_decals.insert_decal(
        light_texture_entity,
        @light.ClusteredDecal::ClusteredDecal().with_tag(5U),
      ),
    )
  })
  match world.get_resource_mut(ecs_key_global_clusterable_object_meta) {
    Some(meta_ref) =>
      meta_ref.modify(fn(meta) { meta.insert_entity_index(decal_entity, 99) })
    None => ()
  }
  match world.get_resource(prepare_clustered_decals_schedule_probe_key) {
    Some(probe) => {
      probe.decal_entity = Some(decal_entity)
      probe.light_texture_entity = Some(light_texture_entity)
    }
    None => ()
  }
}

///|
test "render3d: pbr plugin registers dummy meshlet visibility resolve shader" {
  @shader_source.clear_embedded_shader_sources()
  ignore(
    @app.App::new(@ecs.World::new())
    .add_plugins(@asset.AssetPlugin::AssetPlugin())
    .add_plugins(@time.TimePlugin::TimePlugin())
    .add_plugins(@render.RenderPlugin::RenderPlugin())
    .add_plugins(PbrPlugin::PbrPlugin()),
  )
  let dummy_source = match
    @shader_source.embedded_shader_source(
      "pbr/meshlet/dummy_visibility_buffer_resolve.wgsl",
    ) {
    Some(source) => source
    None => abort("missing dummy meshlet visibility resolve shader")
  }
  debug_inspect(
    dummy_source.contains(
      "#define_import_path bevy_pbr::meshlet_visibility_buffer_resolve",
    ),
    content="true",
  )
}

///|
test "render3d: pbr plugin registers deferred shader libraries when deferred plugin is disabled" {
  @shader_source.clear_embedded_shader_sources()
  ignore(
    @app.App::new(@ecs.World::new())
    .add_plugins(@asset.AssetPlugin::AssetPlugin())
    .add_plugins(@time.TimePlugin::TimePlugin())
    .add_plugins(@render.RenderPlugin::RenderPlugin())
    .add_plugins(PbrPlugin::{
      ..PbrPlugin::PbrPlugin(),
      add_default_deferred_lighting_plugin: false,
    }),
  )
  let deferred_types_source = match
    @shader_source.embedded_shader_source(
      "pbr/deferred/pbr_deferred_types.wgsl",
    ) {
    Some(source) => source
    None => abort("missing deferred PBR types shader")
  }
  let deferred_functions_source = match
    @shader_source.embedded_shader_source(
      "pbr/deferred/pbr_deferred_functions.wgsl",
    ) {
    Some(source) => source
    None => abort("missing deferred PBR functions shader")
  }
  debug_inspect(
    deferred_types_source.contains(
      "#define_import_path bevy_pbr::pbr_deferred_types",
    ),
    content="true",
  )
  debug_inspect(
    deferred_functions_source.contains(
      "#define_import_path bevy_pbr::pbr_deferred_functions",
    ),
    content="true",
  )
}

///|
fn assert_embedded_shader_source_exists(path : String) -> Unit {
  match @shader_source.embedded_shader_source(path) {
    Some(_) => ()
    None => abort("missing embedded shader source: \{path}")
  }
}

///|
test "render3d: pbr plugin registers bevy pbr shader library list" {
  @shader_source.clear_embedded_shader_sources()
  ignore(
    @app.App::new(@ecs.World::new())
    .add_plugins(@asset.AssetPlugin::AssetPlugin())
    .add_plugins(@time.TimePlugin::TimePlugin())
    .add_plugins(@render.RenderPlugin::RenderPlugin())
    .add_plugins(PbrPlugin::{
      ..PbrPlugin::PbrPlugin(),
      add_default_deferred_lighting_plugin: false,
    }),
  )
  assert_embedded_shader_source_exists("pbr/render/pbr_types.wgsl")
  assert_embedded_shader_source_exists("pbr/render/pbr_bindings.wgsl")
  assert_embedded_shader_source_exists("pbr/render/utils.wgsl")
  assert_embedded_shader_source_exists("pbr/render/clustered_forward.wgsl")
  assert_embedded_shader_source_exists("pbr/render/pbr_lighting.wgsl")
  assert_embedded_shader_source_exists("pbr/render/shadows.wgsl")
  assert_embedded_shader_source_exists("pbr/deferred/pbr_deferred_types.wgsl")
  assert_embedded_shader_source_exists(
    "pbr/deferred/pbr_deferred_functions.wgsl",
  )
  assert_embedded_shader_source_exists("pbr/render/shadow_sampling.wgsl")
  assert_embedded_shader_source_exists("pbr/render/pbr_functions.wgsl")
  assert_embedded_shader_source_exists("pbr/render/rgb9e5.wgsl")
  assert_embedded_shader_source_exists("pbr/render/pbr_ambient.wgsl")
  assert_embedded_shader_source_exists("pbr/render/pbr_fragment.wgsl")
  assert_embedded_shader_source_exists("pbr/render/pbr.wgsl")
  assert_embedded_shader_source_exists("pbr/render/pbr_prepass_functions.wgsl")
  assert_embedded_shader_source_exists("pbr/render/pbr_prepass.wgsl")
  assert_embedded_shader_source_exists("pbr/render/parallax_mapping.wgsl")
  assert_embedded_shader_source_exists("pbr/render/view_transformations.wgsl")
  assert_embedded_shader_source_exists(
    "pbr/meshlet/dummy_visibility_buffer_resolve.wgsl",
  )
}

///|
test "render3d: screen space transmission plugin registers shader and camera requirements" {
  @shader_source.clear_embedded_shader_sources()
  let app = @app.App::new(@ecs.World::new())
    .add_plugins(@asset.AssetPlugin::AssetPlugin())
    .add_plugins(@render.RenderPlugin::RenderPlugin())
    .add_plugins(ScreenSpaceTransmissionPlugin::ScreenSpaceTransmissionPlugin())
  let shader_source = match
    @shader_source.embedded_shader_source("pbr/transmission/transmission.wgsl") {
    Some(source) => source
    None => abort("missing screen-space transmission shader")
  }
  debug_inspect(
    shader_source.contains("#define_import_path bevy_pbr::transmission"),
    content="true",
  )
  let entity = app.world().spawn_empty()
  try! (app.world().set_by_key(entity, ecs_key_camera3d, Camera3d::Camera3d())
  |> ignore)
  debug_inspect(
    (try! app.world().get_by_key(entity, ecs_key_screen_space_transmission))
    is Some(_),
    content="true",
  )
  debug_inspect(
    (try! app.world().get_by_key(entity, @render.ecs_key_sync_to_render_world))
    is Some(_),
    content="true",
  )
}

///|
test "render3d: gpu clustering plugin registers build shader library" {
  @shader_source.clear_embedded_shader_sources()
  ignore(
    @app.App::new(@ecs.World::new())
    .add_plugins(@asset.AssetPlugin::AssetPlugin())
    .add_plugins(@render.RenderPlugin::RenderPlugin())
    .add_plugins(GpuClusteringPlugin::GpuClusteringPlugin()),
  )
  let cluster_source = match
    @shader_source.embedded_shader_source("pbr/cluster/cluster.wgsl") {
    Some(source) => source
    None => abort("missing GPU clustering cluster shader")
  }
  debug_inspect(
    cluster_source.contains("#define_import_path bevy_pbr::cluster"),
    content="true",
  )
}

///|
test "render3d: gpu clustering pipelines specialize Bevy-shaped descriptors" {
  let raster = ClusteringRasterPipeline::ClusteringRasterPipeline()
  let count_descriptor = raster.specialize(
    ClusteringRasterPipelineKey::count_pass(),
  )
  debug_inspect(
    count_descriptor.label(),
    content="Some(\"clustering count pipeline\")",
  )
  debug_inspect(
    count_descriptor.layout()[0].label(),
    content="\"clustering count pass bind group layout\"",
  )
  let count_fragment = count_descriptor.fragment().unwrap()
  debug_inspect(
    count_fragment.shader(),
    content="Some(\"pbr/cluster/cluster_raster.wgsl\")",
  )
  debug_inspect(count_fragment.entry_point(), content="Some(\"fragment_main\")")
  match count_fragment.targets()[0] {
    Some(target) => {
      if target.format() != @wgpu.TEXTURE_FORMAT_R8_UNORM {
        abort("clustering raster target must use R8Unorm")
      }
      debug_inspect(target.write_mask(), content="0")
    }
    None => abort("missing clustering raster color target")
  }
  let populate_descriptor = raster.specialize(
    ClusteringRasterPipelineKey::new_populate_pass(),
  )
  debug_inspect(
    populate_descriptor.layout()[0].label(),
    content="\"clustering populate pass bind group layout\"",
  )
  let z_descriptor = ClusteringZSlicingPipeline::ClusteringZSlicingPipeline().specialize()
  debug_inspect(
    z_descriptor.label(),
    content="Some(\"clustering Z slicing pipeline\")",
  )
  debug_inspect(
    z_descriptor.shader(),
    content="Some(\"pbr/cluster/cluster_z_slice.wgsl\")",
  )
  debug_inspect(z_descriptor.entry_point(), content="Some(\"z_slice_main\")")
  let allocation = ClusteringAllocationPipeline::ClusteringAllocationPipeline()
  debug_inspect(
    allocation
    .specialize(ClusteringAllocationPipelineKey::local_pass())
    .entry_point(),
    content="Some(\"allocate_local_main\")",
  )
  debug_inspect(
    allocation
    .specialize(ClusteringAllocationPipelineKey::new_global_pass())
    .entry_point(),
    content="Some(\"allocate_global_main\")",
  )
  let cache = @render_resource.PipelineCache::new()
  let raster_cache = SpecializedClusteringRasterPipelines::SpecializedClusteringRasterPipelines()
  let count_id = raster_cache.queue(
    cache,
    raster,
    ClusteringRasterPipelineKey::count_pass(),
  )
  let count_id_again = raster_cache.queue(
    cache,
    raster,
    ClusteringRasterPipelineKey::count_pass(),
  )
  debug_inspect(count_id.id() == count_id_again.id(), content="true")
  debug_inspect(raster_cache.len(), content="1")
  ignore(
    raster_cache.queue(
      cache,
      raster,
      ClusteringRasterPipelineKey::new_populate_pass(),
    ),
  )
  debug_inspect(raster_cache.len(), content="2")
  let z_cache = SpecializedClusteringZSlicingPipelines::SpecializedClusteringZSlicingPipelines()
  ignore(
    z_cache.queue(
      cache,
      ClusteringZSlicingPipeline::ClusteringZSlicingPipeline(),
    ),
  )
  ignore(
    z_cache.queue(
      cache,
      ClusteringZSlicingPipeline::ClusteringZSlicingPipeline(),
    ),
  )
  debug_inspect(z_cache.len(), content="1")
  let allocation_cache = SpecializedClusteringAllocationPipelines::SpecializedClusteringAllocationPipelines()
  ignore(
    allocation_cache.queue(
      cache,
      allocation,
      ClusteringAllocationPipelineKey::local_pass(),
    ),
  )
  ignore(
    allocation_cache.queue(
      cache,
      allocation,
      ClusteringAllocationPipelineKey::new_global_pass(),
    ),
  )
  debug_inspect(allocation_cache.len(), content="2")
}

///|
test "render3d: gpu clustering prepare queues per-view pipeline ids" {
  let world = @ecs.World::new()
  world.insert_resource(
    @render.pipeline_cache_resource_key,
    @render_resource.PipelineCache::new(),
  )
  world.insert_resource(
    SpecializedClusteringRasterPipelines::resource(),
    SpecializedClusteringRasterPipelines::SpecializedClusteringRasterPipelines(),
  )
  world.insert_resource(
    SpecializedClusteringZSlicingPipelines::resource(),
    SpecializedClusteringZSlicingPipelines::SpecializedClusteringZSlicingPipelines(),
  )
  world.insert_resource(
    SpecializedClusteringAllocationPipelines::resource(),
    SpecializedClusteringAllocationPipelines::SpecializedClusteringAllocationPipelines(),
  )
  world.insert_resource(
    ClusteringRasterPipeline::resource(),
    ClusteringRasterPipeline::ClusteringRasterPipeline(),
  )
  world.insert_resource(
    ClusteringZSlicingPipeline::resource(),
    ClusteringZSlicingPipeline::ClusteringZSlicingPipeline(),
  )
  world.insert_resource(
    ClusteringAllocationPipeline::resource(),
    ClusteringAllocationPipeline::ClusteringAllocationPipeline(),
  )
  let view_a = world.spawn()
  let view_b = world.spawn()
  try! world.set_by_key(
    view_a,
    @render_view.ExtractedView::component(),
    @render_view.ExtractedView::new(
      @render_view.RetainedViewEntity::new(view_a),
    ),
  )
  try! world.set_by_key(
    view_b,
    @render_view.ExtractedView::component(),
    @render_view.ExtractedView::new(
      @render_view.RetainedViewEntity::new(view_b),
    ),
  )

  prepare_clustering_pipelines(world)

  let ids_a = match
    (try! world.get_by_key(view_a, ViewGpuClusteringPipelineIds::component())) {
    Some(value) => value
    None => abort("missing view A GPU clustering pipeline ids")
  }
  let ids_b = match
    (try! world.get_by_key(view_b, ViewGpuClusteringPipelineIds::component())) {
    Some(value) => value
    None => abort("missing view B GPU clustering pipeline ids")
  }
  debug_inspect(
    ids_a.clustering_z_slicing_pipeline_id().id(),
    content=ids_b.clustering_z_slicing_pipeline_id().id().to_string(),
  )
  debug_inspect(
    ids_a.clustering_count_pipeline_id().id(),
    content=ids_b.clustering_count_pipeline_id().id().to_string(),
  )
  debug_inspect(
    ids_a.clustering_allocation_local_pipeline_id().id(),
    content=ids_b.clustering_allocation_local_pipeline_id().id().to_string(),
  )
  debug_inspect(
    ids_a.clustering_allocation_global_pipeline_id().id(),
    content=ids_b.clustering_allocation_global_pipeline_id().id().to_string(),
  )
  debug_inspect(
    ids_a.clustering_populate_pipeline_id().id(),
    content=ids_b.clustering_populate_pipeline_id().id().to_string(),
  )
  debug_inspect(
    world
    .get_resource(@render.pipeline_cache_resource_key)
    .unwrap()
    .queued_pipeline_count(),
    content="5",
  )
  debug_inspect(
    world
    .get_resource(SpecializedClusteringRasterPipelines::resource())
    .unwrap()
    .len(),
    content="2",
  )
  debug_inspect(
    world
    .get_resource(SpecializedClusteringZSlicingPipelines::resource())
    .unwrap()
    .len(),
    content="1",
  )
  debug_inspect(
    world
    .get_resource(SpecializedClusteringAllocationPipelines::resource())
    .unwrap()
    .len(),
    content="2",
  )
}

///|
test "render3d: gpu clustering run condition follows global cluster settings" {
  let world = @ecs.World::new()
  debug_inspect(gpu_clustering_is_enabled(world), content="false")
  world.insert_resource(
    @light_cluster.GlobalClusterSettings::resource(),
    @light_cluster.GlobalClusterSettings::GlobalClusterSettings(),
  )
  debug_inspect(gpu_clustering_is_enabled(world), content="true")
}

///|
test "render3d: gpu clustering prepare creates dummy textures per extracted view" {
  let instance = @wgpu.Instance::create()
  let adapter = instance.request_adapter_sync()
  let device = adapter.request_device_sync(instance)
  let render_device = @renderer.RenderDevice::from_wgpu(device)
  let world = @ecs.World::new()
  world.insert_resource(@render.render_device_resource_key, render_device)
  world.insert_resource(
    @render_texture.TextureCache::resource(),
    @render_texture.TextureCache::new(),
  )
  let view_a = world.spawn()
  let view_b = world.spawn()
  try! world.set_by_key(
    view_a,
    @render_view.ExtractedView::component(),
    @render_view.ExtractedView::new(
      @render_view.RetainedViewEntity::new(view_a),
    ),
  )
  try! world.set_by_key(
    view_a,
    ExtractedClusterConfig::component(),
    ExtractedClusterConfig::new(0.1F, 1000.0F, 33, 65, 24),
  )
  try! world.set_by_key(
    view_b,
    @render_view.ExtractedView::component(),
    @render_view.ExtractedView::new(
      @render_view.RetainedViewEntity::new(view_b),
    ),
  )
  try! world.set_by_key(
    view_b,
    ExtractedClusterConfig::component(),
    ExtractedClusterConfig::new(0.1F, 1000.0F, 33, 65, 24),
  )

  prepare_cluster_dummy_textures(world)

  debug_inspect(
    (try! world.get_by_key(view_a, ViewClusteringDummyTexture::component()))
    is Some(_),
    content="true",
  )
  debug_inspect(
    (try! world.get_by_key(view_b, ViewClusteringDummyTexture::component()))
    is Some(_),
    content="true",
  )
  let texture_cache = world
    .get_resource(@render_texture.TextureCache::resource())
    .unwrap()
  debug_inspect(texture_cache.descriptor_count(), content="1")
  debug_inspect(texture_cache.len(), content="2")
  debug_inspect(texture_cache.taken_count(), content="2")

  device.release()
  adapter.release()
  instance.release()
}

///|
test "render3d: prepare_lights writes view uniform offsets for camera views" {
  let instance = @wgpu.Instance::create()
  let adapter = instance.request_adapter_sync()
  let device = adapter.request_device_sync(instance)
  let render_device = @renderer.RenderDevice::from_wgpu(device)
  let render_queue = render_device.queue()
  let world = @ecs.World::new()
  world.insert_resource(@render.render_device_resource_key, render_device)
  world.insert_resource(@render.render_queue_resource_key, render_queue)
  world.insert_resource(
    @pbr_render.LightMeta::resource(),
    @pbr_render.LightMeta::LightMeta(),
  )
  let direct_view = world.spawn()
  let main_view = world.spawn()
  let indirect_view = world.spawn()
  let non_camera_view = world.spawn()
  try! world.set_by_key(
    direct_view,
    @render_view.ExtractedView::component(),
    @render_view.ExtractedView::new(
      @render_view.RetainedViewEntity::new(direct_view),
    ),
  )
  try! world.set_by_key(direct_view, ecs_key_camera3d, Camera3d::Camera3d())
  try! world.set_by_key(main_view, ecs_key_camera3d, Camera3d::Camera3d())
  try! world.set_by_key(
    indirect_view,
    @render_view.ExtractedView::component(),
    @render_view.ExtractedView::new(
      @render_view.RetainedViewEntity::new(indirect_view),
    ),
  )
  try! world.set_by_key(
    indirect_view,
    @render.ecs_key_main_entity,
    @render.MainEntity::new(main_view),
  )
  try! world.set_by_key(
    non_camera_view,
    @render_view.ExtractedView::component(),
    @render_view.ExtractedView::new(
      @render_view.RetainedViewEntity::new(non_camera_view),
    ),
  )

  prepare_lights(world)

  let direct_offset = match
    (try! world.get_by_key(
      direct_view,
      @pbr_render.ViewLightsUniformOffset::component(),
    )) {
    Some(value) => value
    None => abort("missing direct view lights uniform offset")
  }
  let indirect_offset = match
    (try! world.get_by_key(
      indirect_view,
      @pbr_render.ViewLightsUniformOffset::component(),
    )) {
    Some(value) => value
    None => abort("missing indirect view lights uniform offset")
  }
  let uniform_size = @pbr_render.render3d_gpu_lights_uniform_bytes(
      @pbr_render.GpuLights3d::GpuLights3d(),
    )
    .length()
    .reinterpret_as_uint()
  debug_inspect(direct_offset.offset(), content="0")
  debug_inspect(indirect_offset.offset(), content=uniform_size.to_string())
  debug_inspect(
    (try! world.get_by_key(
      non_camera_view,
      @pbr_render.ViewLightsUniformOffset::component(),
    ))
    is None,
    content="true",
  )
  let direct_view_lights = match
    (try! world.get_by_key(
      direct_view,
      @pbr_render.ViewLightEntities::component(),
    )) {
    Some(value) => value
    None => abort("missing direct view light entities")
  }
  let indirect_view_lights = match
    (try! world.get_by_key(
      indirect_view,
      @pbr_render.ViewLightEntities::component(),
    )) {
    Some(value) => value
    None => abort("missing indirect view light entities")
  }
  debug_inspect(direct_view_lights.len(), content="0")
  debug_inspect(indirect_view_lights.len(), content="0")
  debug_inspect(
    (try! world.get_by_key(
      non_camera_view,
      @pbr_render.ViewLightEntities::component(),
    ))
    is None,
    content="true",
  )
  let light_meta = world
    .get_resource(@pbr_render.LightMeta::resource())
    .unwrap()
  debug_inspect(light_meta.view_gpu_lights_len(), content="2")
  debug_inspect(light_meta.view_gpu_lights_binding() is Some(_), content="true")

  device.release()
  adapter.release()
  instance.release()
}

///|
test "render3d: NoIndirectDrawing reuses render view owner key" {
  debug_inspect(
    ecs_key_no_indirect_drawing.id() ==
    @render_view.ecs_key_no_indirect_drawing.id(),
    content="true",
  )
  let world = @ecs.World::new()
  let entity = world.spawn()
  try! world.set_by_key(
    entity,
    ecs_key_no_indirect_drawing,
    NoIndirectDrawing::NoIndirectDrawing(),
  )
  debug_inspect(
    (try! world.get_by_key(entity, @render_view.NoIndirectDrawing::component()))
    is Some(_),
    content="true",
  )
}

///|
test "render3d: prepare_lights packs render-world extracted lights" {
  let app0 = @app.App::new(@ecs.World::new())
    .add_plugins(@asset.AssetPlugin::AssetPlugin())
    .add_plugins(@time.TimePlugin::TimePlugin())
    .add_plugins(@light.LightPlugin::LightPlugin())
    .add_plugins(@render.RenderPlugin::RenderPlugin())
    .add_plugins(PbrPlugin::PbrPlugin())
  let mut app = app0
  let camera = app.world().spawn()
  try! app.world().set_by_key(camera, ecs_key_camera3d, Camera3d::Camera3d())
  let directional_light = app.world().spawn()
  try! app
  .world()
  .set_by_key(
    directional_light,
    @light.ecs_key_directional_light,
    @light.DirectionalLight::DirectionalLight(),
  )
  try! app
  .world()
  .set_by_key(
    directional_light,
    @transform.ecs_key_transform,
    @transform.Transform::identity(),
  )
  try! app
  .world()
  .set_by_key(
    directional_light,
    @visibility.ecs_key_view_visibility,
    @visibility.ViewVisibility::new(true),
  )

  app = app.update()
  let render_world = app.sub_app(@app.RenderApp).world()
  let view = render_world.spawn()
  try! render_world.set_by_key(
    view,
    @render_view.ExtractedView::component(),
    @render_view.ExtractedView::new(@render_view.RetainedViewEntity::new(view)),
  )
  try! render_world.set_by_key(
    view,
    @render.ecs_key_main_entity,
    @render.MainEntity::new(camera),
  )

  prepare_lights(render_world)

  let light_meta = render_world
    .get_resource(@pbr_render.LightMeta::resource())
    .unwrap()
  let gpu_lights = match light_meta.view_gpu_lights_at(0) {
    Some(value) => value
    None => abort("missing prepared view GPU lights")
  }
  debug_inspect(gpu_lights.n_directional_lights, content="1")
  debug_inspect(
    @pbr_render.render3d_collect_gpu_lights(app.world()).n_directional_lights,
    content="0",
  )
}

///|
test "render3d: prepare_lights runs after the camera driver set" {
  let instance = @wgpu.Instance::create()
  let adapter = instance.request_adapter_sync()
  let device = adapter.request_device_sync(instance)
  let render_device = @renderer.RenderDevice::from_wgpu(device)
  let render_queue = render_device.queue()
  let app0 = @app.App::new(@ecs.World::new())
    .add_plugins(@asset.AssetPlugin::AssetPlugin())
    .add_plugins(@time.TimePlugin::TimePlugin())
    .add_plugins(@light.LightPlugin::LightPlugin())
    .add_plugins(@shader.ShaderPlugin::ShaderPlugin())
    .add_plugins(@render.RenderPlugin::RenderPlugin())
    .add_plugins(@core_pipeline.CorePipelinePlugin::CorePipelinePlugin())
    .add_plugins(PbrPlugin::PbrPlugin())
  let mut app = app0
  ignore(
    app.modify_sub_app(@app.RenderApp, fn(render_app) {
      render_app
      .world()
      .insert_resource(@render.render_device_resource_key, render_device)
      render_app
      .world()
      .insert_resource(@render.render_queue_resource_key, render_queue)
      render_app
      .world()
      .insert_resource(prepare_lights_schedule_probe_key, PrepareLightsScheduleProbe::{
        spawned_view: None,
      })
      render_app.add_systems(
        @render.render_schedule_stage(),
        @app.system(prepare_lights_schedule_spawn_view)
        .in_set(@core_pipeline.core_pipeline_camera_driver_set)
        .in_set(@render.render_system_set_create_views),
      )
    }),
  )

  app = app.update()

  let render_world = app.sub_app(@app.RenderApp).world()
  let spawned_view = match
    render_world.get_resource(prepare_lights_schedule_probe_key).unwrap().spawned_view {
    Some(entity) => entity
    None => abort("camera driver probe did not spawn a view")
  }
  debug_inspect(
    (try! render_world.get_by_key(
      spawned_view,
      @pbr_render.ViewLightsUniformOffset::component(),
    ))
    is Some(_),
    content="true",
  )
  debug_inspect(
    (try! render_world.get_by_key(
      spawned_view,
      @pbr_render.ViewLightEntities::component(),
    ))
    is Some(_),
    content="true",
  )

  device.release()
  adapter.release()
  instance.release()
}

///|
test "render3d: clustered decals prepare after prepare_lights" {
  let instance = @wgpu.Instance::create()
  let adapter = instance.request_adapter_sync()
  let device = adapter.request_device_sync(instance)
  let render_device = @renderer.RenderDevice::from_wgpu(device)
  let render_queue = render_device.queue()
  let app0 = @app.App::new(@ecs.World::new())
    .add_plugins(@asset.AssetPlugin::AssetPlugin())
    .add_plugins(@time.TimePlugin::TimePlugin())
    .add_plugins(@light.LightPlugin::LightPlugin())
    .add_plugins(@shader.ShaderPlugin::ShaderPlugin())
    .add_plugins(@render.RenderPlugin::RenderPlugin())
    .add_plugins(@core_pipeline.CorePipelinePlugin::CorePipelinePlugin())
    .add_plugins(PbrPlugin::PbrPlugin())
  let mut app = app0
  ignore(
    app.modify_sub_app(@app.RenderApp, fn(render_app) {
      render_app
      .world()
      .insert_resource(@render.render_device_resource_key, render_device)
      render_app
      .world()
      .insert_resource(@render.render_queue_resource_key, render_queue)
      render_app
      .world()
      .insert_resource(prepare_clustered_decals_schedule_probe_key, PrepareClusteredDecalsScheduleProbe::{
        decal_entity: None,
        light_texture_entity: None,
      })
      render_app.add_systems(
        @render.render_schedule_stage(),
        @app.system(prepare_clustered_decals_schedule_seed)
        .in_set(@core_pipeline.core_pipeline_camera_driver_set)
        .in_set(@render.render_system_set_create_views),
      )
    }),
  )

  app = app.update()

  let render_world = app.sub_app(@app.RenderApp).world()
  let decal_entity = match
    render_world
    .get_resource(prepare_clustered_decals_schedule_probe_key)
    .unwrap().decal_entity {
    Some(entity) => entity
    None => abort("clustered decal schedule probe did not seed a decal")
  }
  let light_texture_entity = match
    render_world
    .get_resource(prepare_clustered_decals_schedule_probe_key)
    .unwrap().light_texture_entity {
    Some(entity) => entity
    None => abort("clustered decal schedule probe did not seed a light texture")
  }
  let meta = match
    render_world.get_resource(ecs_key_global_clusterable_object_meta) {
    Some(value) => value
    None => abort("missing GlobalClusterableObjectMeta")
  }
  debug_inspect(meta.entity_index(decal_entity), content="Some(0)")
  debug_inspect(meta.entity_index(light_texture_entity), content="None")
  debug_inspect(meta.entity_to_index_len(), content="1")

  device.release()
  adapter.release()
  instance.release()
}

///|
test "render3d: gpu clustering prepare creates per-view buffers" {
  let instance = @wgpu.Instance::create()
  let adapter = instance.request_adapter_sync()
  let device = adapter.request_device_sync(instance)
  let render_device = @renderer.RenderDevice::from_wgpu(device)
  let render_queue = render_device.queue()
  let world = @ecs.World::new()
  world.insert_resource(@render.render_device_resource_key, render_device)
  world.insert_resource(@render.render_queue_resource_key, render_queue)
  world.insert_resource(
    @light_cluster.GlobalClusterSettings::resource(),
    @light_cluster.GlobalClusterSettings::new(
      true,
      true,
      Some(@light_cluster.GlobalClusterGpuSettings::new(8, 16)),
      204,
      16384,
    ),
  )
  let meta = GlobalClusterableObjectMeta::new(
    @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
  )
  meta.add_gpu_clustered_light(GpuClusteredLight::GpuClusteredLight())
  meta.add_gpu_clustered_light(GpuClusteredLight::GpuClusteredLight())
  meta.write_gpu_clustered_lights_buffer(render_device, render_queue)
  world.insert_resource(GlobalClusterableObjectMeta::resource(), meta)
  let readback = RenderViewClusteringReadbackData::RenderViewClusteringReadbackData()
  readback.views.set(
    @core.Entity::new(999, 1).to_bits(),
    ViewClusteringReadbackData::new(
      @light_cluster.GlobalClusterGpuSettings::new(4, 4),
    ),
  )
  world.insert_resource(RenderViewClusteringReadbackData::resource(), readback)
  let render_decals = @pbr_decal.RenderClusteredDecals::RenderClusteredDecals()
  ignore(
    render_decals.insert_decal(
      @core.Entity::new(200, 1),
      @light.ClusteredDecal::ClusteredDecal(),
    ),
  )
  world.insert_resource(
    @pbr_decal.RenderClusteredDecals::resource(),
    render_decals,
  )
  let view = world.spawn()
  let main_view = @core.Entity::new(10, 1)
  try! world.set_by_key(
    view,
    @render_view.ExtractedView::component(),
    @render_view.ExtractedView::new(@render_view.RetainedViewEntity::new(view)),
  )
  try! world.set_by_key(
    view,
    @render.ecs_key_main_entity,
    @render.MainEntity::new(main_view),
  )
  try! world.set_by_key(
    view,
    ExtractedClusterConfig::component(),
    ExtractedClusterConfig::new(0.1F, 1000.0F, 2, 3, 4),
  )
  let probes = @pbr_light_probe.RenderViewLightProbes::RenderViewLightProbes()
  probes.push_probe(@pbr_light_probe.RenderLightProbe::RenderLightProbe())
  probes.push_probe(@pbr_light_probe.RenderLightProbe::RenderLightProbe())
  let irradiance_probes = @pbr_light_probe.RenderViewLightProbes::RenderViewLightProbes()
  irradiance_probes.push_probe(
    @pbr_light_probe.RenderLightProbe::RenderLightProbe(),
  )
  try! world.set_by_key(
    view,
    @pbr_light_probe.RenderViewEnvironmentMapLightProbes::component(),
    @pbr_light_probe.RenderViewEnvironmentMapLightProbes::new(probes),
  )
  try! world.set_by_key(
    view,
    @pbr_light_probe.RenderViewIrradianceVolumeLightProbes::component(),
    @pbr_light_probe.RenderViewIrradianceVolumeLightProbes::new(
      irradiance_probes,
    ),
  )

  prepare_clusters_for_gpu_clustering(world)

  let bindings = match
    (try! world.get_by_key(view, ViewClusterBindings::component())) {
    Some(value) => value
    None => abort("missing ViewClusterBindings")
  }
  let buffers = match
    (try! world.get_by_key(view, ViewGpuClusteringBuffers::component())) {
    Some(value) => value
    None => abort("missing ViewGpuClusteringBuffers")
  }
  let metadata = buffers.metadata()
  debug_inspect(bindings.n_offsets(), content="24")
  debug_inspect(bindings.cluster_offsets_len(), content="24")
  debug_inspect(bindings.n_indices(), content="16")
  debug_inspect(bindings.clusterable_object_index_lists_len(), content="16")
  debug_inspect(
    bindings.cluster_offsets_and_counts_gpu_buffer() is Some(_),
    content="true",
  )
  debug_inspect(
    bindings.clusterable_object_index_lists_gpu_buffer() is Some(_),
    content="true",
  )
  debug_inspect(
    bindings.cluster_offsets_and_counts_gpu_capacity() > 0UL,
    content="true",
  )
  debug_inspect(
    bindings.clusterable_object_index_lists_gpu_capacity() > 0UL,
    content="true",
  )
  debug_inspect(buffers.z_slices_len(), content="8")
  debug_inspect(buffers.scratchpad_offsets_and_counts_len(), content="24")
  debug_inspect(metadata.clustered_light_count(), content="2")
  debug_inspect(metadata.reflection_probe_count(), content="2")
  debug_inspect(metadata.irradiance_volume_count(), content="1")
  debug_inspect(metadata.decal_count(), content="1")
  debug_inspect(metadata.index_list_capacity(), content="16")
  debug_inspect(metadata.z_slice_list_capacity(), content="8")
  let readback_after = world
    .get_resource(RenderViewClusteringReadbackData::resource())
    .unwrap()
  debug_inspect(readback_after.len(), content="1")
  debug_inspect(
    readback_after.contains_main_entity(@render.MainEntity::new(main_view)),
    content="true",
  )

  upload_view_gpu_clustering_buffers(world)

  let uploaded_buffers = match
    (try! world.get_by_key(view, ViewGpuClusteringBuffers::component())) {
    Some(value) => value
    None => abort("missing uploaded ViewGpuClusteringBuffers")
  }
  debug_inspect(
    uploaded_buffers.z_slices_gpu_buffer() is Some(_),
    content="true",
  )
  debug_inspect(
    uploaded_buffers.cluster_metadata_gpu_buffer() is Some(_),
    content="true",
  )
  debug_inspect(
    uploaded_buffers.scratchpad_offsets_and_counts_gpu_buffer() is Some(_),
    content="true",
  )
  debug_inspect(uploaded_buffers.z_slices_gpu_capacity() > 0UL, content="true")
  debug_inspect(
    uploaded_buffers.cluster_metadata_gpu_capacity() > 0UL,
    content="true",
  )
  debug_inspect(
    uploaded_buffers.scratchpad_offsets_and_counts_gpu_capacity() > 0UL,
    content="true",
  )

  let light_probes_buffer = @pbr_light_probe.LightProbesBuffer::LightProbesBuffer()
  ignore(
    light_probes_buffer.push_uniform_bytes(
      Bytes::make(@pbr_light_probe.LIGHT_PROBES_UNIFORM_SIZE_BYTES, b'\x00'),
    ),
  )
  light_probes_buffer.write_buffer(
    render_device.wgpu_device(),
    render_queue.wgpu_queue(),
  )
  world.insert_resource(
    @pbr_light_probe.LightProbesBuffer::resource(),
    light_probes_buffer,
  )
  let decals_buffer = @pbr_decal.DecalsBuffer::DecalsBuffer()
  @pbr_decal.render3d_upload_decals(render_decals, decals_buffer)
  decals_buffer.write_buffer(
    render_device.wgpu_device(),
    render_queue.wgpu_queue(),
  )
  world.insert_resource(@pbr_decal.DecalsBuffer::resource(), decals_buffer)
  let light_meta = @pbr_render.LightMeta::LightMeta()
  ignore(
    light_meta.push_view_gpu_lights(@pbr_render.GpuLights3d::GpuLights3d()),
  )
  light_meta.write_view_gpu_lights_buffer(
    render_device.wgpu_device(),
    render_queue.wgpu_queue(),
  )
  world.insert_resource(@pbr_render.LightMeta::resource(), light_meta)
  let view_uniforms = @render_view.ViewUniforms::ViewUniforms()
  ignore(view_uniforms.push(@render_view.ViewUniform::ViewUniform()))
  view_uniforms.write_buffer(
    render_device.wgpu_device(),
    render_queue.wgpu_queue(),
  )
  world.insert_resource(@render_view.ViewUniforms::resource(), view_uniforms)
  world.insert_resource(
    ClusteringRasterPipeline::resource(),
    ClusteringRasterPipeline::ClusteringRasterPipeline(),
  )
  world.insert_resource(
    ClusteringZSlicingPipeline::resource(),
    ClusteringZSlicingPipeline::ClusteringZSlicingPipeline(),
  )
  world.insert_resource(
    ClusteringAllocationPipeline::resource(),
    ClusteringAllocationPipeline::ClusteringAllocationPipeline(),
  )

  prepare_clustering_bind_groups(world)

  debug_inspect(
    (try! world.get_by_key(view, ViewClusteringBindGroups::component()))
    is Some(_),
    content="true",
  )

  device.release()
  adapter.release()
  instance.release()
}

///|
test "render3d: gpu clustering extract writes configs and syncs readback statistics" {
  let world = @ecs.World::new()
  let source_view = world.spawn()
  let render_view = world.spawn()
  let clusters = @light_cluster.Clusters::new(120, 120, 2, 3, 4, 0.5F, 96.0F)
  try! world.set_by_key(
    source_view,
    @light_cluster.Clusters::component(),
    clusters,
  )
  try! world.set_by_key(
    source_view,
    @camera_camera.ecs_key_camera,
    @camera_camera.Camera::Camera(),
  )
  try! world.set_by_key(
    source_view,
    @render.ecs_key_render_entity,
    @render.RenderEntity::new(render_view),
  )
  let readback = RenderViewClusteringReadbackData::RenderViewClusteringReadbackData()
  let view_readback = ViewClusteringReadbackData::new(
    @light_cluster.GlobalClusterGpuSettings::new(8, 16),
  )
  let farthest_z = 19.25F
  view_readback.update_from_metadata(
    ClusterMetadata::from_gpu_readback(
      ClusterRasterIndirectDrawParams::new(6U, 0U, 0U, 0U, 0U),
      0U,
      0U,
      0U,
      0U,
      8U,
      33U,
      farthest_z.reinterpret_as_uint() ^ 0x8000_0000U,
    ),
  )
  readback.views.set(source_view.to_bits(), view_readback)
  world.insert_resource(RenderViewClusteringReadbackData::resource(), readback)

  extract_clusters_for_gpu_clustering(world)

  let extracted_config = match
    (try! world.get_by_key(render_view, ExtractedClusterConfig::component())) {
    Some(value) => value
    None => abort("missing ExtractedClusterConfig")
  }
  debug_inspect(extracted_config.dimensions(), content="(2, 3, 4)")
  debug_inspect(extracted_config.near(), content="0.5")
  debug_inspect(extracted_config.far(), content="96")
  let updated_clusters = match
    (try! world.get_by_key(source_view, @light_cluster.Clusters::component())) {
    Some(value) => value
    None => abort("missing source clusters")
  }
  debug_inspect(
    updated_clusters.last_frame_total_cluster_index_count(),
    content="Some(33)",
  )
  debug_inspect(updated_clusters.last_frame_farthest_z(), content="Some(19.25)")
}

///|
test "render3d: cpu clustering prepare writes Bevy-shaped view cluster bindings" {
  let instance = @wgpu.Instance::create()
  let adapter = instance.request_adapter_sync()
  let device = adapter.request_device_sync(instance)
  let render_device = @renderer.RenderDevice::from_wgpu(device)
  let render_queue = render_device.queue()
  let world = @ecs.World::new()
  world.insert_resource(@render.render_device_resource_key, render_device)
  world.insert_resource(@render.render_queue_resource_key, render_queue)
  world.insert_resource(
    @light_cluster.GlobalClusterSettings::resource(),
    @light_cluster.GlobalClusterSettings::new(true, true, None, 204, 16384),
  )
  let light_entity = @core.Entity::new(21, 1)
  let decal_entity = @core.Entity::new(22, 1)
  let reflection_probe = @render.MainEntity::new(@core.Entity::new(23, 1))
  let irradiance_volume = @render.MainEntity::new(@core.Entity::new(24, 1))
  let meta = GlobalClusterableObjectMeta::new(
    @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
  )
  meta.insert_entity_index(light_entity, 7)
  meta.insert_entity_index(decal_entity, 9)
  world.insert_resource(GlobalClusterableObjectMeta::resource(), meta)
  let view = world.spawn()
  try! world.set_by_key(
    view,
    ExtractedClusterableObjects::component(),
    ExtractedClusterableObjects::new([
      ExtractedClusterableObjectElement::ClusterHeader(
        ClusterableObjectCounts3d::new(1U, 0U, 1U, 1U, 1U),
      ),
      ExtractedClusterableObjectElement::Light(light_entity),
      ExtractedClusterableObjectElement::ReflectionProbe(reflection_probe),
      ExtractedClusterableObjectElement::IrradianceVolume(irradiance_volume),
      ExtractedClusterableObjectElement::Decal(decal_entity),
    ]),
  )
  let reflection_probes = @pbr_light_probe.RenderViewLightProbes::RenderViewLightProbes()
  reflection_probes.push_probe_for_main_entity(
    reflection_probe,
    @pbr_light_probe.RenderLightProbe::RenderLightProbe(),
  )
  let irradiance_probes = @pbr_light_probe.RenderViewLightProbes::RenderViewLightProbes()
  irradiance_probes.push_probe_for_main_entity(
    irradiance_volume,
    @pbr_light_probe.RenderLightProbe::RenderLightProbe(),
  )
  try! world.set_by_key(
    view,
    @pbr_light_probe.RenderViewEnvironmentMapLightProbes::component(),
    @pbr_light_probe.RenderViewEnvironmentMapLightProbes::new(reflection_probes),
  )
  try! world.set_by_key(
    view,
    @pbr_light_probe.RenderViewIrradianceVolumeLightProbes::component(),
    @pbr_light_probe.RenderViewIrradianceVolumeLightProbes::new(
      irradiance_probes,
    ),
  )

  prepare_clusters_for_cpu_clustering(world)

  let bindings = match
    (try! world.get_by_key(view, ViewClusterBindings::component())) {
    Some(value) => value
    None => abort("missing ViewClusterBindings")
  }
  debug_inspect(bindings.n_offsets(), content="1")
  debug_inspect(bindings.n_indices(), content="4")
  debug_inspect(bindings.cluster_offsets_len(), content="1")
  debug_inspect(bindings.clusterable_object_index_lists_len(), content="4")
  debug_inspect(
    bindings.cluster_offsets_and_counts_gpu_buffer() is Some(_),
    content="true",
  )
  debug_inspect(
    bindings.clusterable_object_index_lists_gpu_buffer() is Some(_),
    content="true",
  )

  device.release()
  adapter.release()
  instance.release()
}

///|
test "render3d: gpu clustering readback data reuses staging buffers" {
  let instance = @wgpu.Instance::create()
  let adapter = instance.request_adapter_sync()
  let device = adapter.request_device_sync(instance)
  let render_device = @renderer.RenderDevice::from_wgpu(device)
  let readback = ViewClusteringReadbackData::new(
    @light_cluster.GlobalClusterGpuSettings::new(8, 16),
  )
  debug_inspect(readback.pending_staging_buffer_count(), content="0")
  debug_inspect(readback.free_staging_buffer_count(), content="0")

  let first = readback.get_or_create_staging_buffer(render_device)
  debug_inspect(readback.pending_staging_buffer_count(), content="1")
  debug_inspect(readback.free_staging_buffer_count(), content="0")

  readback.recycle_staging_buffer(first)
  debug_inspect(readback.pending_staging_buffer_count(), content="1")
  debug_inspect(readback.free_staging_buffer_count(), content="1")

  let second = readback.get_or_create_staging_buffer(render_device)
  debug_inspect(readback.pending_staging_buffer_count(), content="2")
  debug_inspect(readback.free_staging_buffer_count(), content="0")

  second.release()
  adapter.release()
  instance.release()
}

///|
test "render3d: gpu clustering readback metadata updates capacities and statistics" {
  let readback = ViewClusteringReadbackData::new(
    @light_cluster.GlobalClusterGpuSettings::new(8, 16),
  )
  let farthest_z = 12.5F
  let encoded_farthest_z = farthest_z.reinterpret_as_uint() ^ 0x8000_0000U
  let metadata = ClusterMetadata::from_gpu_readback(
    ClusterRasterIndirectDrawParams::new(6U, 17U, 0U, 0U, 0U),
    0U,
    0U,
    0U,
    0U,
    8U,
    33U,
    encoded_farthest_z,
  )

  readback.update_from_metadata(metadata)

  debug_inspect(readback.z_slice_list_capacity(), content="32")
  debug_inspect(readback.max_index_list_capacity(), content="64")
  let statistics = match readback.last_frame_statistics() {
    Some(value) => value
    None => abort("missing GPU clustering readback statistics")
  }
  debug_inspect(statistics.index_list_size(), content="33")
  debug_inspect(statistics.farthest_z(), content="12.5")
}

///|
fn gpu_clustering_test_push_u32_le(out : Array[Byte], value : UInt) -> Unit {
  out.push((value & 0xFFU).reinterpret_as_int().to_byte())
  out.push(((value >> 8) & 0xFFU).reinterpret_as_int().to_byte())
  out.push(((value >> 16) & 0xFFU).reinterpret_as_int().to_byte())
  out.push(((value >> 24) & 0xFFU).reinterpret_as_int().to_byte())
}

///|
test "render3d: gpu clustering readback bytes decode cluster metadata layout" {
  let farthest_z = 21.25F
  let encoded_farthest_z = farthest_z.reinterpret_as_uint() ^ 0x8000_0000U
  let raw : Array[Byte] = []
  for
    value in [
      9U, 18U, 3U, 4U, 5U, 6U, 7U, 8U, 10U, 11U, 12U, encoded_farthest_z,
    ] {
    gpu_clustering_test_push_u32_le(raw, value)
  }
  let bytes = Bytes::from_array(raw)

  let decoded = match ClusterMetadata::from_readback_bytes(bytes) {
    Some(value) => value
    None => abort("failed to decode GPU clustering metadata bytes")
  }
  let params = decoded.indirect_draw_params()
  debug_inspect(params.index_count(), content="9")
  debug_inspect(params.instance_count(), content="18")
  debug_inspect(params.first_index(), content="3")
  debug_inspect(params.base_vertex(), content="4")
  debug_inspect(params.first_instance(), content="5")
  debug_inspect(decoded.clustered_light_count(), content="6")
  debug_inspect(decoded.reflection_probe_count(), content="7")
  debug_inspect(decoded.irradiance_volume_count(), content="8")
  debug_inspect(decoded.decal_count(), content="10")
  debug_inspect(decoded.z_slice_list_capacity(), content="11")
  debug_inspect(decoded.index_list_capacity(), content="12")
  debug_inspect(decoded.farthest_z(), content=encoded_farthest_z.to_string())
  debug_inspect(
    ClusterMetadata::from_readback_bytes(Bytes::from_array([])) is None,
    content="true",
  )
}

///|
test "render3d: gpu clustering plugin finish initializes render resources" {
  let instance = @wgpu.Instance::create()
  let adapter = instance.request_adapter_sync()
  let device = adapter.request_device_sync(instance)
  let storage_buffers = device.limits_max_storage_buffers_per_shader_stage_u32()
  let app0 = @app.App::new(@ecs.World::new())
    .add_plugins(@asset.AssetPlugin::AssetPlugin())
    .add_plugins(@render.RenderPlugin::RenderPlugin())
    .add_plugins(GpuClusteringPlugin::GpuClusteringPlugin())
  ignore(
    app0.modify_sub_app(@app.RenderApp, fn(render_app) {
      let render_world = render_app.world()
      render_world.insert_resource(
        @render.render_device_resource_key,
        @renderer.RenderDevice::from_wgpu(device),
      )
      render_world.insert_resource(
        @render.pipeline_cache_resource_key,
        @render_resource.PipelineCache::new(),
      )
      render_app
    }),
  )
  let app = app0.finish()
  let render_app = app.get_sub_app(@app.RenderApp).unwrap()
  let render_world = render_app.world()
  let expected = storage_buffers > 0U
  debug_inspect(
    render_world
    .resource(SpecializedClusteringRasterPipelines::resource())
    .is_present(),
    content=expected.to_string(),
  )
  debug_inspect(
    render_world
    .resource(SpecializedClusteringZSlicingPipelines::resource())
    .is_present(),
    content=expected.to_string(),
  )
  debug_inspect(
    render_world
    .resource(SpecializedClusteringAllocationPipelines::resource())
    .is_present(),
    content=expected.to_string(),
  )
  debug_inspect(
    render_world
    .resource(RenderViewClusteringReadbackData::resource())
    .is_present(),
    content=expected.to_string(),
  )
  debug_inspect(
    render_world.resource(GpuClusteringMeshBuffers::resource()).is_present(),
    content=expected.to_string(),
  )
  if expected {
    let mesh_buffers = render_world
      .get_resource(GpuClusteringMeshBuffers::resource())
      .unwrap()
    debug_inspect(mesh_buffers.vertex_buffer().size(), content="32")
    debug_inspect(mesh_buffers.index_buffer().size(), content="24")
  }
  device.release()
  adapter.release()
  instance.release()
}

///|
fn read_global_cluster_settings(
  world : @ecs.World,
) -> @light_cluster.GlobalClusterSettings {
  match world.get_resource(@light_cluster.GlobalClusterSettings::resource()) {
    Some(settings) => settings
    None => abort("missing GlobalClusterSettings resource")
  }
}

///|
fn render_world_with_fog_meta(app : @app.App[@ecs.World]) -> Bool {
  match app.get_sub_app(@app.RenderApp) {
    Some(render_sub_app) => {
      let render_world = render_sub_app.world()
      render_world.get_resource(@pbr_render.FogMeta::resource()) is Some(_)
    }
    None => false
  }
}

///|
fn render_world_with_material_resources(app : @app.App[@ecs.World]) -> Bool {
  match app.get_sub_app(@app.RenderApp) {
    Some(render_sub_app) => {
      let render_world = render_sub_app.world()
      render_world.get_resource(ecs_key_entity_specialization_ticks) is Some(_) &&
      render_world.get_resource(ecs_key_specialized_material_pipeline_cache)
      is Some(_) &&
      render_world.get_resource(ecs_key_render_material_instances) is Some(_)
    }
    None => false
  }
}

///|
fn mesh_assets_mut_or_abort(
  world : @ecs.World,
) -> @ecs.ResourceMut[@asset.Assets[@mesh.Mesh]] {
  let key : @ecs.ResourceKey[@asset.Assets[@mesh.Mesh]] = @asset.assets_resource_key()
  match world.get_resource_mut(key) {
    Some(assets) => assets
    None => abort("missing Assets<Mesh> resource")
  }
}

///|
fn pbr_app_with_mesh3d_entity() -> (
  @app.App[@ecs.World],
  @core.Entity,
  @asset.Handle[@mesh.Mesh],
) {
  let app = @app.App::new(@ecs.World::new())
    .add_plugins(@asset.AssetPlugin::AssetPlugin())
    .add_plugins(@mesh.MeshPlugin::MeshPlugin())
    .add_plugins(@render.RenderPlugin::RenderPlugin())
    .add_plugins(PbrPlugin::PbrPlugin())
  let world = app.world()
  let mesh_handle = mesh_assets_mut_or_abort(world).modify(fn(assets) {
    assets.add(
      @mesh.Mesh::from_3d_geometry(@mesh_primitives.rectangle_mesh(1.0F, 1.0F)),
    )
  })
  let entity = world.spawn()
  try! world.set(entity, @mesh.Mesh3d::new(mesh_handle))
  world.increment_change_tick() |> ignore
  world.increment_change_tick() |> ignore
  (app, entity, mesh_handle)
}

///|
test "render3d: plugin replacement id aligns with bevy_pbr" {
  let plugin = PbrPlugin::PbrPlugin()
  debug_inspect(plugin.name(), content="\"mgstudio.pbr.PbrPlugin\"")
}

///|
test "render3d: modified Mesh asset marks Mesh3d as changed (bevy semantics)" {
  let (app0, entity, mesh_handle) = pbr_app_with_mesh3d_entity()
  let mut app = app0
  let before = app.world().read_change_tick()

  debug_inspect(
    mesh_assets_mut_or_abort(app.world()).modify(fn(assets) {
      assets.set(
        mesh_handle,
        @mesh.Mesh::from_3d_geometry(
          @mesh_primitives.rectangle_mesh(2.0F, 2.0F),
        ),
      )
    }),
    content="true",
  )

  app = app.update()
  let after = app.world().read_change_tick()
  let changed = app
    .world()
    .changed_components(ecs_key_mesh3d, @core.SystemTicks::new(before, after))
    .read()
  debug_inspect(changed.contains(entity), content="true")
}

///|
test "render3d: non-modified Mesh asset events do not mark Mesh3d as changed" {
  let (app0, entity, _mesh_handle) = pbr_app_with_mesh3d_entity()
  let mut app = app0
  let before = app.world().read_change_tick()
  app = app.update()
  let after = app.world().read_change_tick()
  let changed = app
    .world()
    .changed_components(ecs_key_mesh3d, @core.SystemTicks::new(before, after))
    .read()
  debug_inspect(changed.contains(entity), content="false")
}

///|
test "render3d: default pbr plugin installs bevy-style runtime config defaults" {
  let app = pbr_plugin(
    @app.App::new(@ecs.World::new())
    .add_plugins(@asset.AssetPlugin::AssetPlugin())
    .add_plugins(@render.RenderPlugin::RenderPlugin()),
  )
  let config = read_pbr_runtime_config(app.world())
  debug_inspect(config.prepass_enabled, content="true")
  debug_inspect(config.add_default_deferred_lighting_plugin, content="true")
  debug_inspect(config.use_gpu_instance_buffer_builder, content="true")
  debug_inspect(config.gltf_render_enabled, content="true")
  debug_inspect(
    config.debug_flags.allow_copies_from_indirect_parameters(),
    content="false",
  )
  debug_inspect(
    read_mesh_render_plugin_state(app.world()).use_gpu_instance_buffer_builder,
    content="true",
  )
  debug_inspect(
    read_mesh_render_plugin_state(app.world()).debug_flags.allow_copies_from_indirect_parameters(),
    content="false",
  )
  debug_inspect(
    read_materials_plugin_state(app.world())
    .debug_flags()
    .allow_copies_from_indirect_parameters(),
    content="false",
  )
  debug_inspect(
    app.contains_resource(ecs_key_materials_plugin_state),
    content="true",
  )
  debug_inspect(render_world_with_material_resources(app), content="true")
  debug_inspect(render_world_with_fog_meta(app), content="true")
  debug_inspect(
    app.contains_resource(ecs_key_scattering_medium_plugin_state),
    content="true",
  )
  debug_inspect(
    read_deferred_lighting_state(app.world()).enabled,
    content="true",
  )
  debug_inspect(
    read_standard_material_plugin_state(app.world()).prepass_enabled,
    content="true",
  )
  debug_inspect(
    read_standard_material_plugin_state(app.world())
    .debug_flags()
    .allow_copies_from_indirect_parameters(),
    content="false",
  )
  debug_inspect(
    app.contains_resource(@pbr_prepass.ecs_key_any_prepass_plugin_loaded),
    content="true",
  )
  debug_inspect(
    read_any_prepass_plugin_loaded(app.world())
    .debug_flags()
    .allow_copies_from_indirect_parameters(),
    content="false",
  )
  let default_material = read_default_standard_material(app.world())
  debug_inspect(
    @color.color_approx_eq(
      default_material.base_color,
      @color.Color::srgb(1.0F, 0.0F, 0.5F),
      0.000001F,
    ),
    content="true",
  )
}

///|
test "render3d: pbr plugin forwards gpu preprocess builder setting" {
  let app = @app.App::new(@ecs.World::new())
    .add_plugins(@asset.AssetPlugin::AssetPlugin())
    .add_plugins(@render.RenderPlugin::RenderPlugin())
    .add_plugins(PbrPlugin::{
      ..PbrPlugin::PbrPlugin(),
      use_gpu_instance_buffer_builder: false,
    })
  let state = read_gpu_preprocess_state(app.world())
  debug_inspect(state.indirect_enabled(), content="false")
}

///|
test "render3d: pbr plugin finish initializes global cluster settings" {
  let instance = @wgpu.Instance::create()
  let adapter = instance.request_adapter_sync()
  let device = adapter.request_device_sync(instance)
  let expected_supports_storage = device.supports_read_only_storage_buffer_binding(
    CLUSTERED_FORWARD_STORAGE_BUFFER_COUNT,
  )
  let expected_gpu_clustering = device.limits_max_storage_buffers_per_shader_stage_u32() >
    0U
  let expected_clustered_decals = @render.host_gpu_mesh3d_binding_arrays_are_usable(
    required_storage_textures_per_shader_stage=0U,
  )
  let app0 = @app.App::new(@ecs.World::new())
    .add_plugins(@asset.AssetPlugin::AssetPlugin())
    .add_plugins(@render.RenderPlugin::RenderPlugin())
  ignore(
    app0.modify_sub_app(@app.RenderApp, fn(render_app) {
      render_app
      .world()
      .insert_resource(
        @render.render_device_resource_key,
        @renderer.RenderDevice::from_wgpu(device),
      )
      render_app
    }),
  )
  let app = app0.add_plugins(PbrPlugin::PbrPlugin()).finish()
  let settings = read_global_cluster_settings(app.world())
  if settings.supports_storage_buffers() != expected_supports_storage {
    abort(
      "GlobalClusterSettings storage-buffer support did not match RenderDevice limits",
    )
  }
  if settings.clustered_decals_are_usable() != expected_clustered_decals {
    abort(
      "GlobalClusterSettings clustered decal support did not match render helper",
    )
  }
  debug_inspect(
    settings.max_uniform_buffer_clusterable_objects(),
    content="204",
  )
  debug_inspect(settings.view_cluster_bindings_max_indices(), content="16384")
  match settings.gpu_clustering() {
    Some(gpu) => {
      if !expected_gpu_clustering {
        abort(
          "GlobalClusterSettings enabled GPU clustering without storage-buffer support",
        )
      }
      debug_inspect(gpu.initial_z_slice_list_capacity(), content="1024")
      debug_inspect(gpu.initial_index_list_capacity(), content="65536")
    }
    None =>
      if expected_gpu_clustering {
        abort("GlobalClusterSettings missed GPU clustering support")
      }
  }
  device.release()
  adapter.release()
  instance.release()
}

///|
test "render3d: pbr plugin installs Bevy-shaped render startup resources" {
  let instance = @wgpu.Instance::create()
  let adapter = instance.request_adapter_sync()
  let device = adapter.request_device_sync(instance)
  let expected_binding_type = device.get_supported_read_only_binding_type_u32(
    CLUSTERED_FORWARD_STORAGE_BUFFER_COUNT,
  )
  let app = @app.App::new(@ecs.World::new())
    .add_plugins(@asset.AssetPlugin::AssetPlugin())
    .add_plugins(@render.RenderPlugin::RenderPlugin())
    .add_plugins(PbrPlugin::PbrPlugin())
  let render_sub_app = app
    .sub_app(@app.RenderApp)
    .set_update_schedule(Some(@render.render_startup_schedule_stage()))
  let render_world = render_sub_app.world()
  debug_inspect(
    render_world.resource(@pbr_render.ecs_key_shadow_samplers).is_present(),
    content="false",
  )
  debug_inspect(
    render_world.resource(ecs_key_global_clusterable_object_meta).is_present(),
    content="false",
  )
  debug_inspect(
    render_world.resource(ecs_key_fallback_bindless_resources).is_present(),
    content="false",
  )
  render_world.insert_resource(
    @render.render_device_resource_key,
    @renderer.RenderDevice::from_wgpu(device),
  )
  ignore(render_sub_app.run_startup())
  debug_inspect(
    render_world.resource(@pbr_render.ecs_key_shadow_samplers).is_present(),
    content="true",
  )
  debug_inspect(
    render_world.resource(ecs_key_fallback_bindless_resources).is_present(),
    content="true",
  )
  let meta = match
    render_world.get_resource(ecs_key_global_clusterable_object_meta) {
    Some(value) => value
    None => abort("missing GlobalClusterableObjectMeta resource")
  }
  debug_inspect(meta.entity_to_index_len(), content="0")
  if meta.gpu_clustered_lights().binding_type() != expected_binding_type {
    abort(
      "GlobalClusterableObjectMeta binding type did not match RenderDevice limits",
    )
  }
  device.release()
  adapter.release()
  instance.release()
}

///|
test "render3d: pbr plugin initializes Bevy-shaped render resources" {
  let app = @app.App::new(@ecs.World::new())
    .add_plugins(@asset.AssetPlugin::AssetPlugin())
    .add_plugins(@render.RenderPlugin::RenderPlugin())
    .add_plugins(PbrPlugin::PbrPlugin())
  let render_world = app.sub_app(@app.RenderApp).world()
  let light_meta = match
    render_world.get_resource(@pbr_render.LightMeta::resource()) {
    Some(value) => value
    None => abort("missing LightMeta render resource")
  }
  debug_inspect(light_meta.view_gpu_lights_len(), content="0")
  let material_bindings = match
    render_world.get_resource(RenderMaterialBindings::resource()) {
    Some(value) => value
    None => abort("missing RenderMaterialBindings resource")
  }
  debug_inspect(material_bindings.len(), content="0")
  let shadow_lod_origin = match
    render_world.get_resource(@render_view.RenderShadowLodOrigin::resource()) {
    Some(value) => value
    None => abort("missing RenderShadowLodOrigin resource")
  }
  debug_inspect(shadow_lod_origin.is_default(), content="true")
}

///|
test "render3d: pbr plugin extracts global ambient light through render schedule" {
  let app0 = @app.App::new(@ecs.World::new())
    .add_plugins(@asset.AssetPlugin::AssetPlugin())
    .add_plugins(@time.TimePlugin::TimePlugin())
    .add_plugins(@render.RenderPlugin::RenderPlugin())
    .add_plugins(PbrPlugin::PbrPlugin())
  let mut app = app0
  app
  .world()
  .insert_resource(
    @light.ecs_key_global_ambient_light,
    @light.GlobalAmbientLight::new(
      @color.Color::new(0.25F, 0.5F, 0.75F, 1.0F),
      2.0F,
    ).with_affects_lightmapped_meshes(false),
  )

  app = app.update()
  let first_render_world = app.sub_app(@app.RenderApp).world()
  let first_changed_tick = first_render_world
    .resource_changed_tick(@light.ecs_key_global_ambient_light)
    .unwrap()
  let first_ambient = first_render_world
    .get_resource(@light.ecs_key_global_ambient_light)
    .unwrap()
  debug_inspect(first_ambient.brightness, content="2")
  debug_inspect(first_ambient.affects_lightmapped_meshes, content="false")

  app = app.update()
  let second_render_world = app.sub_app(@app.RenderApp).world()
  let unchanged_tick = second_render_world
    .resource_changed_tick(@light.ecs_key_global_ambient_light)
    .unwrap()
  debug_inspect(unchanged_tick == first_changed_tick, content="true")

  app
  .world()
  .insert_resource(
    @light.ecs_key_global_ambient_light,
    @light.GlobalAmbientLight::new(
      @color.Color::new(1.0F, 0.5F, 0.25F, 1.0F),
      6.0F,
    ),
  )
  app = app.update()
  let third_render_world = app.sub_app(@app.RenderApp).world()
  let second_changed_tick = third_render_world
    .resource_changed_tick(@light.ecs_key_global_ambient_light)
    .unwrap()
  let second_ambient = third_render_world
    .get_resource(@light.ecs_key_global_ambient_light)
    .unwrap()
  debug_inspect(second_changed_tick != unchanged_tick, content="true")
  debug_inspect(second_ambient.brightness, content="6")
}

///|
test "render3d: pbr plugin extracts shadow filtering method through render schedule" {
  let app0 = @app.App::new(@ecs.World::new())
    .add_plugins(@asset.AssetPlugin::AssetPlugin())
    .add_plugins(@time.TimePlugin::TimePlugin())
    .add_plugins(@render.RenderPlugin::RenderPlugin())
    .add_plugins(PbrPlugin::PbrPlugin())
  let mut app = app0
  let world = app.world()
  let entity = world.spawn()
  try! world.set_by_key(
    entity,
    ecs_key_shadow_filtering_method,
    ShadowFilteringMethod::Temporal,
  )

  app = app.update()
  let render_entity = match
    (try! app.world().get_by_key(entity, @render.ecs_key_render_entity)) {
    Some(value) => value.id()
    None => abort("missing RenderEntity after sync")
  }
  let render_world = app.sub_app(@app.RenderApp).world()
  let extracted = match
    (try! render_world.get_by_key(
      render_entity, ecs_key_shadow_filtering_method,
    )) {
    Some(value) => value
    None => abort("missing extracted ShadowFilteringMethod")
  }
  debug_inspect(extracted, content="Temporal")

  try! app
  .world()
  .set_by_key(
    entity,
    ecs_key_shadow_filtering_method,
    ShadowFilteringMethod::Hardware2x2,
  )
  app = app.update()
  let updated = match
    (try! app
    .sub_app(@app.RenderApp)
    .world()
    .get_by_key(render_entity, ecs_key_shadow_filtering_method)) {
    Some(value) => value
    None => abort("missing updated ShadowFilteringMethod")
  }
  debug_inspect(updated, content="Hardware2x2")
}

///|
test "render3d: pbr plugin extracts ambient light through render schedule" {
  let app0 = @app.App::new(@ecs.World::new())
    .add_plugins(@asset.AssetPlugin::AssetPlugin())
    .add_plugins(@time.TimePlugin::TimePlugin())
    .add_plugins(@light.LightPlugin::LightPlugin())
    .add_plugins(@render.RenderPlugin::RenderPlugin())
    .add_plugins(PbrPlugin::PbrPlugin())
  let mut app = app0
  let world = app.world()
  let entity = world.spawn()
  try! world.set_by_key(
    entity,
    ecs_key_ambient_light,
    AmbientLight::new(@color.Color::new(0.25F, 0.5F, 0.75F, 1.0F), 12.0F).with_affects_lightmapped_meshes(
      false,
    ),
  )

  app = app.update()
  let render_entity = match
    (try! app.world().get_by_key(entity, @render.ecs_key_render_entity)) {
    Some(value) => value.id()
    None => abort("missing RenderEntity after sync")
  }
  let render_world = app.sub_app(@app.RenderApp).world()
  let extracted = match
    (try! render_world.get_by_key(render_entity, ecs_key_ambient_light)) {
    Some(value) => value
    None => abort("missing extracted AmbientLight")
  }
  debug_inspect(extracted.brightness, content="12")
  debug_inspect(extracted.affects_lightmapped_meshes, content="false")

  try! app
  .world()
  .set_by_key(
    entity,
    ecs_key_ambient_light,
    AmbientLight::new(@color.Color::white(), 32.0F),
  )
  app = app.update()
  let updated = match
    (try! app
    .sub_app(@app.RenderApp)
    .world()
    .get_by_key(render_entity, ecs_key_ambient_light)) {
    Some(value) => value
    None => abort("missing updated AmbientLight")
  }
  debug_inspect(updated.brightness, content="32")
  debug_inspect(updated.affects_lightmapped_meshes, content="true")
}

///|
test "render3d: pbr sync target cleanup removes directional light render target components" {
  let app0 = @app.App::new(@ecs.World::new())
    .add_plugins(@asset.AssetPlugin::AssetPlugin())
    .add_plugins(@time.TimePlugin::TimePlugin())
    .add_plugins(@light.LightPlugin::LightPlugin())
    .add_plugins(@render.RenderPlugin::RenderPlugin())
    .add_plugins(PbrPlugin::PbrPlugin())
  let mut app = app0
  let world = app.world()
  let entity = world.spawn()
  try! world.set_by_key(
    entity,
    @light.ecs_key_directional_light,
    @light.DirectionalLight::DirectionalLight(),
  )
  try! world.set_by_key(
    entity,
    @visibility.ecs_key_view_visibility,
    @visibility.ViewVisibility::new(true),
  )

  app = app.update()
  let render_entity = match
    (try! app.world().get_by_key(entity, @render.ecs_key_render_entity)) {
    Some(value) => value.id()
    None => abort("missing RenderEntity after directional light sync")
  }
  let render_world = app.sub_app(@app.RenderApp).world()
  try! render_world.set_by_key(
    render_entity,
    @pbr_render.ecs_key_directional_light_view_entities,
    @pbr_render.DirectionalLightViewEntities::DirectionalLightViewEntities(),
  )
  try! render_world.set_by_key(
    render_entity,
    @render_visibility.ecs_key_render_shadow_map_visible_entities,
    @render_visibility.RenderShadowMapVisibleEntities::RenderShadowMapVisibleEntities(),
  )
  try! render_world.set_by_key(
    render_entity,
    @render_visibility.ecs_key_render_extracted_shadow_map_visible_entities,
    @render_visibility.RenderExtractedShadowMapVisibleEntities::RenderExtractedShadowMapVisibleEntities(),
  )

  ignore(
    app.world().remove_by_key(entity, @light.ecs_key_directional_light) catch {
      _ => false
    },
  )
  app = app.update()
  let render_world_after = app.sub_app(@app.RenderApp).world()
  debug_inspect(
    (try! render_world_after.get_by_key(
      render_entity, @pbr_render.ecs_key_directional_light_view_entities,
    ))
    is None,
    content="true",
  )
  debug_inspect(
    (try! render_world_after.get_by_key(
      render_entity, @render_visibility.ecs_key_render_shadow_map_visible_entities,
    ))
    is None,
    content="true",
  )
  debug_inspect(
    (try! render_world_after.get_by_key(
      render_entity, @render_visibility.ecs_key_render_extracted_shadow_map_visible_entities,
    ))
    is None,
    content="true",
  )
}

///|
test "render3d: pbr light sync target removers match point spot and rect target bundles" {
  let world = @ecs.World::new()
  let point_entity = world.spawn()
  try! world.set_by_key(
    point_entity,
    @pbr_render.ecs_key_point_and_spot_light_view_entities,
    @pbr_render.PointAndSpotLightViewEntities::new([world.spawn()]),
  )
  try! world.set_by_key(
    point_entity,
    @render_visibility.ecs_key_render_shadow_map_visible_entities,
    @render_visibility.RenderShadowMapVisibleEntities::RenderShadowMapVisibleEntities(),
  )
  try! world.set_by_key(
    point_entity,
    @render_visibility.ecs_key_render_extracted_shadow_map_visible_entities,
    @render_visibility.RenderExtractedShadowMapVisibleEntities::RenderExtractedShadowMapVisibleEntities(),
  )
  ignore(@pbr_render.remove_point_light_sync_target(world, point_entity))
  debug_inspect(
    (try! world.get_by_key(
      point_entity, @pbr_render.ecs_key_point_and_spot_light_view_entities,
    ))
    is None,
    content="true",
  )
  debug_inspect(
    (try! world.get_by_key(
      point_entity, @render_visibility.ecs_key_render_shadow_map_visible_entities,
    ))
    is None,
    content="true",
  )

  let spot_entity = world.spawn()
  try! world.set_by_key(
    spot_entity,
    @pbr_render.ecs_key_point_and_spot_light_view_entities,
    @pbr_render.PointAndSpotLightViewEntities::new([world.spawn()]),
  )
  ignore(@pbr_render.remove_spot_light_sync_target(world, spot_entity))
  debug_inspect(
    (try! world.get_by_key(
      spot_entity, @pbr_render.ecs_key_point_and_spot_light_view_entities,
    ))
    is None,
    content="true",
  )

  let rect_entity = world.spawn()
  try! world.set_by_key(
    rect_entity,
    @light.ecs_key_rect_light,
    @light.RectLight::RectLight(),
  )
  ignore(@pbr_render.remove_rect_light_sync_target(world, rect_entity))
  debug_inspect(
    (try! world.get_by_key(rect_entity, @light.ecs_key_rect_light)) is None,
    content="true",
  )
}

///|
test "render3d: pbr installs light view entity observers in render world" {
  let app0 = @app.App::new(@ecs.World::new())
    .add_plugins(@asset.AssetPlugin::AssetPlugin())
    .add_plugins(@time.TimePlugin::TimePlugin())
    .add_plugins(@light.LightPlugin::LightPlugin())
    .add_plugins(@render.RenderPlugin::RenderPlugin())
    .add_plugins(PbrPlugin::PbrPlugin())
  let mut app = app0
  let light_entity = app.world().spawn()
  try! app
  .world()
  .set_by_key(
    light_entity,
    @light.ecs_key_directional_light,
    @light.DirectionalLight::DirectionalLight(),
  )
  try! app
  .world()
  .set_by_key(
    light_entity,
    @visibility.ecs_key_view_visibility,
    @visibility.ViewVisibility::new(true),
  )
  app = app.update()
  let render_entity = match
    (try! app.world().get_by_key(light_entity, @render.ecs_key_render_entity)) {
    Some(value) => value.id()
    None => abort("missing RenderEntity after directional light sync")
  }
  let render_world = app.sub_app(@app.RenderApp).world()
  debug_inspect(
    (try! render_world.get_by_key(
      render_entity, @pbr_render.ecs_key_directional_light_view_entities,
    ))
    is Some(_),
    content="true",
  )

  let view_entity = render_world.spawn()
  let shadow_view_a = render_world.spawn()
  let shadow_view_b = render_world.spawn()
  let directional_entities = @pbr_render.DirectionalLightViewEntities::DirectionalLightViewEntities()
  directional_entities.insert(view_entity, [shadow_view_a, shadow_view_b])
  try! render_world.set_by_key(
    render_entity, @pbr_render.ecs_key_directional_light_view_entities, directional_entities,
  )
  ignore(
    try! render_world.remove_by_key(
      render_entity, @pbr_render.ecs_key_directional_light_view_entities,
    ),
  )
  debug_inspect(render_world.is_alive(shadow_view_a), content="false")
  debug_inspect(render_world.is_alive(shadow_view_b), content="false")

  let point_light_entity = render_world.spawn()
  let point_shadow_view = render_world.spawn()
  try! render_world.set_by_key(
    point_light_entity,
    @pbr_render.ecs_key_point_and_spot_light_view_entities,
    @pbr_render.PointAndSpotLightViewEntities::new([point_shadow_view]),
  )
  ignore(
    try! render_world.remove_by_key(
      point_light_entity, @pbr_render.ecs_key_point_and_spot_light_view_entities,
    ),
  )
  debug_inspect(render_world.is_alive(point_shadow_view), content="false")
}

///|
test "render3d: pbr plugin extracts shadow LOD origin through render schedule" {
  let app0 = @app.App::new(@ecs.World::new())
    .add_plugins(@asset.AssetPlugin::AssetPlugin())
    .add_plugins(@time.TimePlugin::TimePlugin())
    .add_plugins(@render.RenderPlugin::RenderPlugin())
    .add_plugins(PbrPlugin::PbrPlugin())
  let mut app = app0
  let world = app.world()
  let camera = world.spawn_empty()
  try! world.set_by_key(
    camera,
    @camera_camera.ecs_key_camera,
    @camera_camera.Camera::Camera(),
  )
  try! world.set_by_key(
    camera,
    @camera_camera.ecs_key_render_target,
    @camera_camera.RenderTarget::Screen,
  )
  try! world.set_by_key(
    camera,
    @transform.ecs_key_global_transform,
    @transform.GlobalTransform::from_transform(
      @transform.Transform::from_xyz(3.0F, 4.0F, 5.0F),
    ),
  )

  app = app.update()
  let first_origin = app
    .sub_app(@app.RenderApp)
    .world()
    .get_resource(@render_view.RenderShadowLodOrigin::resource())
    .unwrap()
    .origin()
  debug_inspect(first_origin.x, content="3")
  debug_inspect(first_origin.y, content="4")
  debug_inspect(first_origin.z, content="5")

  let explicit_origin = world.spawn_empty()
  try! world.set_by_key(
    explicit_origin,
    @camera_visibility.ecs_key_shadow_lod_origin,
    @camera_visibility.ShadowLodOrigin::ShadowLodOrigin(),
  )
  try! world.set_by_key(
    explicit_origin,
    @transform.ecs_key_global_transform,
    @transform.GlobalTransform::from_transform(
      @transform.Transform::from_xyz(8.0F, 9.0F, 10.0F),
    ),
  )

  app = app.update()
  let second_origin = app
    .sub_app(@app.RenderApp)
    .world()
    .get_resource(@render_view.RenderShadowLodOrigin::resource())
    .unwrap()
    .origin()
  debug_inspect(second_origin.x, content="8")
  debug_inspect(second_origin.y, content="9")
  debug_inspect(second_origin.z, content="10")
}

///|
fn pbr_extract_material_instance_or_abort(
  app : @app.App[@ecs.World],
  entity : @core.Entity,
) -> RenderMaterialInstance {
  let render_world = app.sub_app(@app.RenderApp).world()
  let instances = render_world
    .get_resource(ecs_key_render_material_instances)
    .unwrap()
  match instances.get(entity) {
    Some(instance) => instance
    None => abort("missing RenderMaterialInstance")
  }
}

///|
test "render3d: pbr plugin extracts and sweeps material instances through render schedule" {
  let app0 = @app.App::new(@ecs.World::new())
    .add_plugins(@asset.AssetPlugin::AssetPlugin())
    .add_plugins(@time.TimePlugin::TimePlugin())
    .add_plugins(@render.RenderPlugin::RenderPlugin())
    .add_plugins(PbrPlugin::PbrPlugin())
  let mut app = app0
  let world = app.world()
  let entity = world.spawn_empty()
  try! world.set_by_key(
    entity,
    ecs_key_mesh3d,
    @mesh.Mesh3d::new(@asset.Handle::new(1)),
  )
  try! world.set_by_key(
    entity,
    ecs_key_mesh_material3d,
    MeshMaterial3d::new(@asset.Handle::new(10)),
  )
  try! world.set_by_key(
    entity,
    @visibility.ecs_key_view_visibility,
    @visibility.ViewVisibility::new(true),
  )

  app = app.update()
  let first_instance = pbr_extract_material_instance_or_abort(app, entity)
  debug_inspect(first_instance.asset_id(), content="10")
  debug_inspect(first_instance.last_change_tick(), content="0")
  debug_inspect(
    app
    .sub_app(@app.RenderApp)
    .world()
    .get_resource(ecs_key_render_material_instances)
    .unwrap()
    .current_change_tick(),
    content="1",
  )

  app.world().increment_change_tick() |> ignore
  ignore(try! app.world().remove_by_key(entity, ecs_key_mesh_material3d))
  app.world().increment_change_tick() |> ignore
  app = app.update()
  debug_inspect(
    app
    .sub_app(@app.RenderApp)
    .world()
    .get_resource(ecs_key_render_material_instances)
    .unwrap()
    .mesh_material(entity),
    content="-1",
  )

  app.world().increment_change_tick() |> ignore
  try! app
  .world()
  .set_by_key(
    entity,
    ecs_key_mesh_material3d,
    MeshMaterial3d::new(@asset.Handle::new(30)),
  )
  app.world().increment_change_tick() |> ignore
  app = app.update()
  debug_inspect(
    pbr_extract_material_instance_or_abort(app, entity).asset_id(),
    content="30",
  )

  app = app.update()
  app.world().increment_change_tick() |> ignore
  ignore(try! app.world().remove_by_key(entity, ecs_key_mesh3d))
  app.world().increment_change_tick() |> ignore
  app = app.update()
  debug_inspect(
    app
    .sub_app(@app.RenderApp)
    .world()
    .get_resource(ecs_key_render_material_instances)
    .unwrap()
    .mesh_material(entity),
    content="-1",
  )
}

///|
test "render3d: Mesh3d tuple insert receives visibility required components" {
  let app = @app.App::new(@ecs.World::new())
    .add_plugins(@mesh.MeshPlugin::MeshPlugin())
    .add_plugins(@visibility.VisibilityPlugin::VisibilityPlugin())
  let world = app.world()
  let entity = world.spawn_empty()
  ignore(
    try! world
    .entity_mut(entity)
    .insert(
      (
        @mesh.Mesh3d::new(@asset.Handle::new(1)),
        MeshMaterial3d::new(@asset.Handle::new(2)),
        @transform.Transform::identity(),
      ),
    ),
  )
  debug_inspect(
    try! world.get_by_key(entity, @visibility.ecs_key_visibility),
    content="Some(Inherited)",
  )
  debug_inspect(
    try! world.get_by_key(entity, @visibility.ecs_key_inherited_visibility),
    content="Some({ visible: true })",
  )
  debug_inspect(
    try! world.get_by_key(entity, @visibility.ecs_key_view_visibility),
    content="Some({ bits: 1 })",
  )
}

///|
test "render3d: pbr plugin extracts lights through render schedule" {
  let app0 = @app.App::new(@ecs.World::new())
    .add_plugins(@asset.AssetPlugin::AssetPlugin())
    .add_plugins(@time.TimePlugin::TimePlugin())
    .add_plugins(@render.RenderPlugin::RenderPlugin())
    .add_plugins(PbrPlugin::PbrPlugin())
  let mut app = app0
  let world = app.world()
  let entity = world.spawn_empty()
  try! (world
  .entity_mut(entity)
  .insert_component(PointLight::PointLight().with_intensity(4.0F * @math.pi()))
  |> ignore)

  app = app.update()
  let render_entity = match
    (try! app.world().get_by_key(entity, @render.ecs_key_render_entity)) {
    Some(value) => value.id()
    None => abort("missing RenderEntity for point light")
  }
  debug_inspect(
    (try! app
    .sub_app(@app.RenderApp)
    .world()
    .get_by_key(render_entity, @pbr_render.ecs_key_extracted_point_light3d))
    is Some(_),
    content="true",
  )

  app.world().increment_change_tick() |> ignore
  try! app
  .world()
  .set_by_key(
    entity,
    @visibility.ecs_key_view_visibility,
    @visibility.ViewVisibility::new(false),
  )
  app.world().increment_change_tick() |> ignore
  app = app.update()
  debug_inspect(
    (try! app
    .sub_app(@app.RenderApp)
    .world()
    .get_by_key(render_entity, @pbr_render.ecs_key_extracted_point_light3d))
    is None,
    content="true",
  )
}

///|
test "render3d: pbr plugin does not cache internal LUTs before renderer backend" {
  let app = @app.App::new(@ecs.World::new())
    .add_plugins(@asset.AssetPlugin::AssetPlugin())
    .add_plugins(@render.RenderPlugin::RenderPlugin())
    .add_plugins(PbrPlugin::PbrPlugin())
  let render_world = app.sub_app(@app.RenderApp).world()
  debug_inspect(
    render_world.get_resource(ecs_key_bluenoise) is None,
    content="true",
  )
  debug_inspect(
    render_world.get_resource(ecs_key_area_light_luts) is None,
    content="true",
  )
  debug_inspect(
    render_world.get_resource(ecs_key_dfg_lut) is None,
    content="true",
  )

  pbr_ensure_render_world_internal_luts(render_world, app.world())
  let resource_ids_are_valid = {
    let bluenoise_valid = match render_world.get_resource(ecs_key_bluenoise) {
      Some(value) => value.texture.id() > 0
      None => true
    }
    let area_light_luts_valid = match
      render_world.get_resource(ecs_key_area_light_luts) {
      Some(value) => value.image.id() > 0
      None => true
    }
    let dfg_lut_valid = match render_world.get_resource(ecs_key_dfg_lut) {
      Some(value) => value.texture.id() > 0
      None => true
    }
    bluenoise_valid && area_light_luts_valid && dfg_lut_valid
  }
  debug_inspect(resource_ids_are_valid, content="true")
  let cached = @asset.asset_with_world(app.world(), fn() {
    let server = match
      app.world().get_resource(@asset.asset_server_resource_key) {
      Some(value) => value
      None => abort("missing AssetServer resource")
    }
    let bluenoise : @asset.Handle[@asset.Image]? = server.get_handle(
      "pbr/bluenoise/stbn.ktx2",
    )
    let area_light_luts : @asset.Handle[@asset.Image]? = server.get_handle(
      "pbr/ltc/ltc.ktx2",
    )
    let dfg_lut : @asset.Handle[@asset.Image]? = server.get_handle(
      "pbr/environment_map/dfg.ktx2",
    )
    (
      bluenoise.map_or(true, fn(handle) { handle.id() > 0 }),
      area_light_luts.map_or(true, fn(handle) { handle.id() > 0 }),
      dfg_lut.map_or(true, fn(handle) { handle.id() > 0 }),
    )
  })
  debug_inspect(cached.0, content="true")
  debug_inspect(cached.1, content="true")
  debug_inspect(cached.2, content="true")
}

///|
test "render3d: pbr plugin config updates runtime feature switches" {
  let _app = pbr_plugin_with(
    @app.App::new(@ecs.World::new())
    .add_plugins(@asset.AssetPlugin::AssetPlugin())
    .add_plugins(@render.RenderPlugin::RenderPlugin()),
    PbrPlugin::{
      prepass_enabled: false,
      add_default_deferred_lighting_plugin: false,
      use_gpu_instance_buffer_builder: false,
      debug_flags: @render.RenderDebugFlags::RenderDebugFlags().with_allow_copies_from_indirect_parameters(
        true,
      ),
      gltf_render_enabled: false,
    },
  )

  debug_inspect(pbr_prepass_enabled(_app.world()), content="false")
  debug_inspect(pbr_deferred_lighting_enabled(_app.world()), content="false")
  debug_inspect(
    pbr_gpu_instance_buffer_builder_enabled(_app.world()),
    content="false",
  )
  debug_inspect(pbr_gltf_render_enabled(_app.world()), content="false")
  debug_inspect(
    pbr_plugin_runtime_config(_app.world()).debug_flags.allow_copies_from_indirect_parameters(),
    content="true",
  )
  debug_inspect(
    @gltf_loader.gltf_pbr_material_handler_enabled(),
    content="false",
  )
  debug_inspect(
    read_mesh_render_plugin_state(_app.world()).use_gpu_instance_buffer_builder,
    content="false",
  )
  debug_inspect(
    read_mesh_render_plugin_state(_app.world()).debug_flags.allow_copies_from_indirect_parameters(),
    content="true",
  )
  debug_inspect(
    read_materials_plugin_state(_app.world())
    .debug_flags()
    .allow_copies_from_indirect_parameters(),
    content="true",
  )
  debug_inspect(
    read_deferred_lighting_state(_app.world()).enabled,
    content="false",
  )
  debug_inspect(
    read_standard_material_plugin_state(_app.world()).prepass_enabled,
    content="false",
  )
  debug_inspect(
    read_standard_material_plugin_state(_app.world())
    .debug_flags()
    .allow_copies_from_indirect_parameters(),
    content="true",
  )
  debug_inspect(
    _app.contains_resource(@pbr_prepass.ecs_key_any_prepass_plugin_loaded),
    content="true",
  )
  debug_inspect(
    read_any_prepass_plugin_loaded(_app.world())
    .debug_flags()
    .allow_copies_from_indirect_parameters(),
    content="true",
  )

  let _reset = pbr_plugin(
    @app.App::new(@ecs.World::new())
    .add_plugins(@asset.AssetPlugin::AssetPlugin())
    .add_plugins(@render.RenderPlugin::RenderPlugin()),
  )
  debug_inspect(
    @gltf_loader.gltf_pbr_material_handler_enabled(),
    content="true",
  )
}

///|
test "render3d: root pbr exposes deferred lighting planning surface" {
  let state = DeferredLightingViewState::new(
    deferred_prepass=true,
    tonemapping=Some(Tonemapping::TonyMcMapface),
    deband_dither=Some(DebandDither::Enabled),
    shadow_filter_method=Some(
      DeferredLightingShadowFilteringMethod::Hardware2x2,
    ),
    normal_prepass=true,
  )
  let prepare = deferred_lighting_prepare_plan(state)
  debug_inspect(prepare.should_prepare, content="true")
  debug_inspect(prepare.shader_defs.length(), content="7")
  debug_inspect(
    prepare.shader_defs[0],
    content="\"DEFERRED_LIGHTING_PIPELINE\"",
  )
  debug_inspect(
    prepare.shader_defs[2],
    content="\"TONEMAP_METHOD_TONY_MC_MAPFACE\"",
  )
  debug_inspect(prepare.shader_defs[4], content="\"NORMAL_PREPASS\"")
  debug_inspect(
    prepare.shader_defs[6],
    content="\"SHADOW_FILTER_METHOD_HARDWARE_2X2\"",
  )

  let pass = deferred_lighting_pass_plan(
    has_pipeline=true,
    has_depth_id_binding=true,
    has_mesh_view_bind_group=true,
    has_view_target=true,
    has_deferred_lighting_id_depth_texture=true,
  )
  debug_inspect(pass.should_run, content="true")
  debug_inspect(pass.bind_group_count, content="3")
  debug_inspect(pass.dynamic_offset_count, content="7")
}

///|
test "render3d: plugin group set(PbrPlugin) overrides runtime config resource" {
  let app = @app.App::new(@ecs.World::new())
    .add_plugins(@asset.AssetPlugin::AssetPlugin())
    .add_plugins(@render.RenderPlugin::RenderPlugin())
    .add_plugins(
      @app.PluginGroupBuilder::start_named("test-pbr")
      .add(PbrPlugin::PbrPlugin())
      .set(PbrPlugin::{
        prepass_enabled: false,
        add_default_deferred_lighting_plugin: false,
        use_gpu_instance_buffer_builder: false,
        debug_flags: @render.RenderDebugFlags::RenderDebugFlags().with_allow_copies_from_indirect_parameters(
          true,
        ),
        gltf_render_enabled: false,
      }),
    )

  let config = read_pbr_runtime_config(app.world())
  debug_inspect(config.prepass_enabled, content="false")
  debug_inspect(config.add_default_deferred_lighting_plugin, content="false")
  debug_inspect(config.use_gpu_instance_buffer_builder, content="false")
  debug_inspect(config.gltf_render_enabled, content="false")
  debug_inspect(
    config.debug_flags.allow_copies_from_indirect_parameters(),
    content="true",
  )
  debug_inspect(
    read_mesh_render_plugin_state(app.world()).use_gpu_instance_buffer_builder,
    content="false",
  )
  debug_inspect(
    read_mesh_render_plugin_state(app.world()).debug_flags.allow_copies_from_indirect_parameters(),
    content="true",
  )
  debug_inspect(
    read_materials_plugin_state(app.world())
    .debug_flags()
    .allow_copies_from_indirect_parameters(),
    content="true",
  )
  debug_inspect(
    read_deferred_lighting_state(app.world()).enabled,
    content="false",
  )
  debug_inspect(
    read_standard_material_plugin_state(app.world()).prepass_enabled,
    content="false",
  )
  debug_inspect(
    read_standard_material_plugin_state(app.world())
    .debug_flags()
    .allow_copies_from_indirect_parameters(),
    content="true",
  )
}

///|
test "render3d: render3d_plugin alias maps to pbr plugin" {
  let app = render3d_plugin(
    @app.App::new(@ecs.World::new())
    .add_plugins(@asset.AssetPlugin::AssetPlugin())
    .add_plugins(@render.RenderPlugin::RenderPlugin()),
  )
  debug_inspect(
    app.contains_resource(ecs_key_pbr_plugin_runtime_config),
    content="true",
  )
  debug_inspect(
    app.contains_resource(ecs_key_mesh_render_plugin_state),
    content="true",
  )
  debug_inspect(
    app.contains_resource(ecs_key_materials_plugin_state),
    content="true",
  )
}
