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
// Bevy source: `bevy/crates/bevy_pbr/src/meshlet/mod.rs`.

///|
pub const MESHLET_MAX_CLUSTER_BUFFER_SLOTS : Int = 33_554_432

///|
const MESHLET_PLUGIN_NAME : String = "mgstudio.pbr.meshlet.MeshletPlugin"

///|
priv struct MeshletPluginMarker {}

///|
let ecs_key_meshlet_plugin_marker : @ecs.ResourceKey[MeshletPluginMarker] = @ecs.register_resource(
  debug_name="mgstudio_pbr::meshlet::MeshletPluginMarker",
)

///|
pub let ecs_key_meshlet_plugin_state : @ecs.ResourceKey[MeshletPluginState] = @ecs.register_resource(
  debug_name="mgstudio_pbr::meshlet::MeshletPluginState",
)

///|
pub let ecs_key_meshlet_instance_manager : @ecs.ResourceKey[InstanceManager] = @ecs.register_resource(
  debug_name="mgstudio_pbr::meshlet::InstanceManager",
)

///|
pub let ecs_key_meshlet_resource_manager : @ecs.ResourceKey[ResourceManager] = @ecs.register_resource(
  debug_name="mgstudio_pbr::meshlet::ResourceManager",
)

///|
pub let ecs_key_meshlet_pipelines : @ecs.ResourceKey[MeshletPipelines] = @ecs.register_resource(
  debug_name="mgstudio_pbr::meshlet::MeshletPipelines",
)

///|
pub let ecs_key_meshlet_mesh_manager : @ecs.ResourceKey[MeshletMeshManager] = @ecs.register_resource(
  debug_name="mgstudio_pbr::meshlet::MeshletMeshManager",
)

///|
pub let ecs_key_meshlet_visibility_buffer_raster_state : @ecs.ResourceKey[
  MeshletVisibilityBufferRasterState,
] = @ecs.register_resource(
  debug_name="mgstudio_pbr::meshlet::MeshletVisibilityBufferRasterState",
)

///|
pub let ecs_key_meshlet_mesh3d : @ecs.ComponentKey[MeshletMesh3d] = @ecs.register_component(
  debug_name="render3d.meshlet_mesh3d",
)

///|
let meshlet_render3d_set_extract : @app.SystemSet = @render.render_system_set_extract_commands

///|
let meshlet_render3d_set_prepare_assets : @app.SystemSet = @render.render_system_set_prepare_assets

///|
let meshlet_render3d_set_manage_views : @app.SystemSet = @render.render_system_set_manage_views

///|
let meshlet_render3d_set_prepare_resources : @app.SystemSet = @render.render_system_set_prepare_resources

///|
let meshlet_render3d_set_prepare_bind_groups : @app.SystemSet = @render.render_system_set_prepare_bind_groups

///|
let meshlet_render3d_set_queue_meshes : @app.SystemSet = @render.render_system_set_queue_meshes

///|
let meshlet_render3d_set_queue_meshes_prepare_materials : @app.SystemSet = @app.system_set(
  "mgstudio.render.queue_meshes.meshlet.prepare_materials",
)

///|
pub fn meshlet_required_wgpu_features() -> UInt64 {
  @renderer.meshlet_required_rust_features_u64()
}

///|
pub fn meshlet_missing_wgpu_features() -> UInt64 {
  @renderer.meshlet_missing_rust_features_u64()
}

///|
pub fn meshlet_runtime_available() -> Bool {
  @renderer.meshlet_required_features_supported()
}

///|
pub(all) enum MeshletRuntimeStatus {
  Enabled
  RuntimeUnavailable
}

///|
pub fn meshlet_runtime_status_from_availability(
  runtime_available : Bool,
) -> MeshletRuntimeStatus {
  if !runtime_available {
    return MeshletRuntimeStatus::RuntimeUnavailable
  }
  MeshletRuntimeStatus::Enabled
}

///|
pub fn meshlet_runtime_status() -> MeshletRuntimeStatus {
  meshlet_runtime_status_from_availability(meshlet_runtime_available())
}

///|
pub struct MeshletPlugin {
  cluster_buffer_slots : Int
}

///|
fn meshlet_cluster_buffer_slots_validate(value : Int) -> Int {
  if value <= 0 {
    abort("MeshletPlugin::cluster_buffer_slots must be greater than zero")
  }
  if value > MESHLET_MAX_CLUSTER_BUFFER_SLOTS {
    abort("MeshletPlugin::cluster_buffer_slots must not be greater than 2^25")
  }
  value
}

///|
pub fn MeshletPlugin::new(cluster_buffer_slots : Int) -> MeshletPlugin {
  MeshletPlugin::{
    cluster_buffer_slots: meshlet_cluster_buffer_slots_validate(
      cluster_buffer_slots,
    ),
  }
}

///|
pub fn MeshletPlugin::required_wgpu_features() -> UInt64 {
  meshlet_required_wgpu_features()
}

///|
pub fn MeshletPlugin::cluster_buffer_slots(self : MeshletPlugin) -> Int {
  self.cluster_buffer_slots
}

///|
pub fn MeshletPlugin::default() -> MeshletPlugin {
  MeshletPlugin::new(1_048_576)
}

///|
pub fn meshlet_plugin() -> MeshletPlugin {
  MeshletPlugin::default()
}

///|
fn meshlet_prepare_assets_system(world : @ecs.World) -> Unit {
  match (try! world.get_resource(ecs_key_meshlet_mesh_manager)) {
    Some(manager) => ignore(perform_pending_meshlet_mesh_writes(manager))
    None => ()
  }
}

///|
fn meshlet_extract_entities_system(world : @ecs.World) -> Unit {
  let source_world = @render.render_source_world(world)
  let instance_count = source_world.component_count(ecs_key_meshlet_mesh3d)
  let manager = extract_meshlet_mesh_entities(instance_count)
  let material_asset_ids = []
  source_world.for_each_component(ecs_key_meshlet_mesh3d, fn(
    _entity,
    meshlet_mesh3d,
  ) {
    material_asset_ids.push(meshlet_mesh3d.id())
  })
  ignore(
    queue_material_meshlet_meshes_with_material_assets(
      manager, material_asset_ids,
    ),
  )
  world.insert_resource(ecs_key_meshlet_instance_manager, manager)
}

///|
fn meshlet_instance_count_from_world(world : @ecs.World) -> Int {
  match (try! world.get_resource(ecs_key_meshlet_instance_manager)) {
    Some(instance_manager) => instance_manager.instance_count()
    None => 0
  }
}

///|
fn meshlet_configure_views_system(world : @ecs.World) -> Unit {
  let source_world = @render.render_source_world(world)
  let msaa_off_views : Array[@core.Entity] = []
  source_world.for_each_component(@core_pipeline.ecs_key_msaa, fn(
    entity,
    msaa,
  ) {
    if msaa is @core_pipeline.Msaa::Off {
      msaa_off_views.push(entity)
    } else {
      abort(
        "MeshletPlugin can't be used with MSAA. Add Msaa::Off to your camera to use this plugin.",
      )
    }
  })
  for view_entity in msaa_off_views {
    try! source_world.set_by_key(
      view_entity,
      ecs_key_meshlet_view_materials_main_opaque_pass,
      MeshletViewMaterialsMainOpaquePass::default(),
    )
    let has_normal_prepass = try! source_world.contains_by_key(
      view_entity, @core_pipeline.ecs_key_normal_prepass,
    )
    let has_motion_vector_prepass = try! source_world.contains_by_key(
      view_entity, @core_pipeline.ecs_key_motion_vector_prepass,
    )
    let has_deferred_prepass = try! source_world.contains_by_key(
      view_entity, @core_pipeline.ecs_key_deferred_prepass,
    )
    if has_normal_prepass || has_motion_vector_prepass {
      try! source_world.set_by_key(
        view_entity,
        ecs_key_meshlet_view_materials_prepass,
        MeshletViewMaterialsPrepass::default(),
      )
    }
    if has_deferred_prepass {
      try! source_world.set_by_key(
        view_entity,
        ecs_key_meshlet_view_materials_deferred_gbuffer_prepass,
        MeshletViewMaterialsDeferredGBufferPrepass::default(),
      )
    }
  }
}

///|
fn meshlet_prepare_resources_system(world : @ecs.World) -> Unit {
  let instance_count = meshlet_instance_count_from_world(world)
  match (try! world.get_resource(ecs_key_meshlet_resource_manager)) {
    Some(manager) =>
      prepare_meshlet_per_frame_resources(manager, instance_count)
    None => ()
  }
}

///|
fn meshlet_prepare_view_bind_groups_system(world : @ecs.World) -> Unit {
  let instance_count = meshlet_instance_count_from_world(world)
  match (try! world.get_resource(ecs_key_meshlet_resource_manager)) {
    Some(_manager) =>
      ignore(prepare_meshlet_view_bind_groups(0, instance_count))
    None => ()
  }
}

///|
fn meshlet_queue_material_meshes_system(world : @ecs.World) -> Unit {
  match (try! world.get_resource(ecs_key_meshlet_instance_manager)) {
    Some(instance_manager) =>
      ignore(queue_material_meshlet_meshes(instance_manager))
    None => ()
  }
}

///|
fn meshlet_prepare_material_views_system(world : @ecs.World) -> Unit {
  let source_world = @render.render_source_world(world)
  let material_ids = match
    (try! world.get_resource(ecs_key_meshlet_instance_manager)) {
    Some(instance_manager) => instance_manager.present_material_ids()
    None => []
  }
  let main_opaque_entities : Array[@core.Entity] = []
  source_world.for_each_component(
    ecs_key_meshlet_view_materials_main_opaque_pass,
    fn(entity, _main_opaque) { main_opaque_entities.push(entity) },
  )
  for entity in main_opaque_entities {
    let main_opaque = MeshletViewMaterialsMainOpaquePass::default()
    prepare_material_meshlet_meshes_main_opaque_pass(main_opaque, material_ids)
    try! source_world.set_by_key(
      entity, ecs_key_meshlet_view_materials_main_opaque_pass, main_opaque,
    )
    let mut prepass = MeshletViewMaterialsPrepass::default()
    let mut deferred = MeshletViewMaterialsDeferredGBufferPrepass::default()
    let has_prepass = try! source_world.contains_by_key(
      entity, ecs_key_meshlet_view_materials_prepass,
    )
    let has_deferred = try! source_world.contains_by_key(
      entity, ecs_key_meshlet_view_materials_deferred_gbuffer_prepass,
    )
    if has_prepass {
      match
        (try! source_world.get_by_key(
          entity, ecs_key_meshlet_view_materials_prepass,
        )) {
        Some(value) => prepass = value
        None => ()
      }
    }
    if has_deferred {
      match
        (try! source_world.get_by_key(
          entity, ecs_key_meshlet_view_materials_deferred_gbuffer_prepass,
        )) {
        Some(value) => deferred = value
        None => ()
      }
    }
    if has_prepass || has_deferred {
      prepare_material_meshlet_meshes_prepass(
        prepass,
        deferred,
        material_ids,
        deferred_enabled=has_deferred,
      )
      if has_prepass {
        try! source_world.set_by_key(
          entity, ecs_key_meshlet_view_materials_prepass, prepass,
        )
      }
      if has_deferred {
        try! source_world.set_by_key(
          entity, ecs_key_meshlet_view_materials_deferred_gbuffer_prepass, deferred,
        )
      }
    }
  }
}

///|
fn meshlet_visibility_buffer_raster_system(world : @ecs.World) -> Unit {
  if (try! world.get_resource(ecs_key_meshlet_visibility_buffer_raster_state))
    is None {
    world.insert_resource(
      ecs_key_meshlet_visibility_buffer_raster_state,
      MeshletVisibilityBufferRasterState::default(),
    )
  }
  let instance_count = meshlet_instance_count_from_world(world)
  match
    (try! world.get_resource_ref_mut(
      ecs_key_meshlet_visibility_buffer_raster_state,
    )) {
    Some(state_ref) =>
      meshlet_visibility_buffer_raster(state_ref.val, instance_count)
    None => ()
  }
}

///|
fn meshlet_prepass_system(world : @ecs.World) -> Unit {
  ignore(meshlet_prepass(meshlet_instance_count_from_world(world)))
}

///|
fn meshlet_deferred_gbuffer_prepass_system(world : @ecs.World) -> Unit {
  ignore(
    meshlet_deferred_gbuffer_prepass(meshlet_instance_count_from_world(world)),
  )
}

///|
fn meshlet_main_opaque_pass_system(world : @ecs.World) -> Unit {
  ignore(meshlet_main_opaque_pass(meshlet_instance_count_from_world(world)))
}

///|
fn meshlet_ensure_render_sub_app_resources(
  world : @ecs.World,
  plugin : MeshletPlugin,
) -> Unit {
  let plugin_state = MeshletPluginState::from_plugin(plugin)
  world.insert_resource(ecs_key_meshlet_plugin_state, plugin_state)
  if (try! world.get_resource(ecs_key_meshlet_instance_manager)) is None {
    world.insert_resource(
      ecs_key_meshlet_instance_manager,
      InstanceManager::default(),
    )
  }
  if plugin_state.runtime_status is RuntimeUnavailable {
    return
  }
  if (try! world.get_resource(ecs_key_meshlet_resource_manager)) is None {
    world.insert_resource(
      ecs_key_meshlet_resource_manager,
      ResourceManager::new(plugin.cluster_buffer_slots()),
    )
  }
  if (try! world.get_resource(ecs_key_meshlet_pipelines)) is None {
    world.insert_resource(
      ecs_key_meshlet_pipelines,
      init_meshlet_pipelines(-1, -1, -1),
    )
  }
  if (try! world.get_resource(ecs_key_meshlet_mesh_manager)) is None {
    world.insert_resource(
      ecs_key_meshlet_mesh_manager,
      MeshletMeshManager::default(),
    )
  }
  if (try! world.get_resource(ecs_key_meshlet_visibility_buffer_raster_state))
    is None {
    world.insert_resource(
      ecs_key_meshlet_visibility_buffer_raster_state,
      MeshletVisibilityBufferRasterState::default(),
    )
  }
}

///|
fn meshlet_configure_render_sub_app(
  sub_app : @app.SubApp[@ecs.World],
  plugin : MeshletPlugin,
) -> @app.SubApp[@ecs.World] {
  meshlet_ensure_render_sub_app_resources(sub_app.world(), plugin)
  let stage = @render.render_schedule_stage()
  @render.configure_base_render_sets(sub_app)
  .add_systems(
    stage,
    @app.system(meshlet_extract_entities_system).in_set(
      meshlet_render3d_set_extract,
    ),
  )
  .add_systems(
    stage,
    @app.system(meshlet_prepare_assets_system).in_set(
      meshlet_render3d_set_prepare_assets,
    ),
  )
  .add_systems(
    stage,
    @app.system(meshlet_configure_views_system).in_set(
      meshlet_render3d_set_manage_views,
    ),
  )
  .add_systems(
    stage,
    @app.system(meshlet_prepare_resources_system).in_set(
      meshlet_render3d_set_prepare_resources,
    ),
  )
  .add_systems(
    stage,
    @app.system(meshlet_prepare_view_bind_groups_system).in_set(
      meshlet_render3d_set_prepare_bind_groups,
    ),
  )
  .add_systems(
    stage,
    @app.system(meshlet_prepare_material_views_system).in_set(
      meshlet_render3d_set_queue_meshes_prepare_materials,
    ),
  )
  .add_systems(
    stage,
    @app.system(meshlet_queue_material_meshes_system).in_set(
      meshlet_render3d_set_queue_meshes,
    ),
  )
  .add_systems(
    stage,
    @app.system(meshlet_visibility_buffer_raster_system).in_set(
      @core_3d.core_3d_set_prepass,
    ),
  )
  .add_systems(
    stage,
    @app.system(meshlet_prepass_system).in_set(@core_3d.core_3d_set_prepass),
  )
  .add_systems(
    stage,
    @app.system(meshlet_deferred_gbuffer_prepass_system).in_set(
      @core_3d.core_3d_set_prepass,
    ),
  )
  .add_systems(
    stage,
    @app.system(meshlet_main_opaque_pass_system).in_set(
      @core_3d.core_3d_set_main_pass,
    ),
  )
  .configure_set(stage, meshlet_render3d_set_manage_views, before=[
    meshlet_render3d_set_queue_meshes_prepare_materials,
  ])
  .configure_set(stage, @render.render_system_set_queue, before=[
    meshlet_render3d_set_queue_meshes_prepare_materials,
  ])
  .configure_set(stage, meshlet_render3d_set_queue_meshes_prepare_materials, before=[
    meshlet_render3d_set_queue_meshes,
  ])
}

///|
pub fn meshlet_plugin_with(
  app : @app.App[@ecs.World],
  plugin : MeshletPlugin,
) -> @app.App[@ecs.World] {
  let plugin_state = MeshletPluginState::from_plugin(plugin)
  let mut next = app.insert_world_resource(
    ecs_key_meshlet_plugin_state, plugin_state,
  )
  if !next.contains_resource(ecs_key_meshlet_plugin_marker) {
    next = next.insert_world_resource(ecs_key_meshlet_plugin_marker, MeshletPluginMarker::{

    })
    next = @render.with_render_app(next, fn(sub_app : @app.SubApp[@ecs.World]) {
      meshlet_configure_render_sub_app(sub_app, plugin)
    })
  }
  next
}

///|
pub impl @app.PluginReplacement for MeshletPlugin with plugin_name(_self) {
  MESHLET_PLUGIN_NAME
}

///|
pub impl @app.PluginReplacement for MeshletPlugin with world_plugin(self) {
  fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
    meshlet_plugin_with(app, self)
  }
}

///|
pub struct MeshletPluginState {
  runtime_status : MeshletRuntimeStatus
  missing_required_features : UInt64
  missing_native_subgroup_barrier : Bool
  missing_native_immediates : Bool
  adapter_supports_mesh_shader : Bool
}

///|
pub fn MeshletPluginState::default() -> MeshletPluginState {
  MeshletPluginState::from_plugin(MeshletPlugin::default())
}

///|
pub fn MeshletPluginState::from_plugin(
  plugin : MeshletPlugin,
) -> MeshletPluginState {
  ignore(plugin)
  MeshletPluginState::{
    runtime_status: meshlet_runtime_status_from_availability(
      meshlet_runtime_available(),
    ),
    missing_required_features: meshlet_missing_wgpu_features(),
    missing_native_subgroup_barrier: @renderer.meshlet_missing_native_subgroup_barrier(),
    missing_native_immediates: @renderer.meshlet_missing_native_immediates(),
    adapter_supports_mesh_shader: @renderer.meshlet_adapter_supports_mesh_shader(),
  }
}

///|
pub struct MeshletMesh3d {
  meshlet_mesh_id : Int
}

///|
pub fn MeshletMesh3d::new(meshlet_mesh_id : Int) -> MeshletMesh3d {
  MeshletMesh3d::{ meshlet_mesh_id, }
}

///|
pub fn MeshletMesh3d::id(self : MeshletMesh3d) -> Int {
  self.meshlet_mesh_id
}

///|
pub impl @ecs.Component for MeshletMesh3d with component() {
  ecs_key_meshlet_mesh3d
}
