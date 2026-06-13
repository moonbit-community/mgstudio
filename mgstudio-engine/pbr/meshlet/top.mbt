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
const MESHLET_MESH_MATERIAL_SHADER_PATH : String = "pbr/meshlet/meshlet_mesh_material.wgsl"

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
let meshlet_render3d_set_create_views : @app.SystemSet = @render.render_system_set_create_views

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
pub fn MeshletPlugin::MeshletPlugin() -> MeshletPlugin {
  MeshletPlugin::new(1_048_576)
}

///|
pub fn meshlet_plugin() -> MeshletPlugin {
  MeshletPlugin::MeshletPlugin()
}

///|
pub fn meshlet_debug_material_add(
  world : @ecs.World,
  material : MeshletDebugMaterial,
) -> @asset.Handle[MeshletDebugMaterial] {
  let key : @ecs.ResourceKey[@asset.Assets[MeshletDebugMaterial]] = @asset.assets_resource_key()
  match world.get_resource_mut(key) {
    Some(assets) => assets.modify(fn(store) { store.add(material) })
    None =>
      abort(
        "Assets<MeshletDebugMaterial> is missing; add MeshletPlugin before creating MeshletDebugMaterial assets",
      )
  }
}

///|
pub fn meshlet_debug_mesh_material3d(
  material : @asset.Handle[MeshletDebugMaterial],
) -> @material.MeshMaterial3d {
  @material.MeshMaterial3d::from_erased_material_id(
    @material.Material3dFamily::MeshletDebug,
    material.id(),
  )
}

///|
fn meshlet_prepare_assets_system(world : @ecs.World) -> Unit {
  match world.get_resource(ecs_key_meshlet_mesh_manager) {
    Some(manager) => ignore(perform_pending_meshlet_mesh_writes(manager))
    _ => ()
  }
}

///|
fn meshlet_extract_entities_system(world : @ecs.World) -> Unit {
  let source_world = @render.render_source_world(world)
  let instance_manager = InstanceManager::InstanceManager()
  let meshlet_assets_key : @ecs.ResourceKey[@asset.Assets[MeshletMesh]] = @asset.assets_resource_key()
  let meshlet_assets = source_world.get_resource(meshlet_assets_key)
  let asset_server = source_world.get_resource(@asset.asset_server_resource_key)
  match (meshlet_assets, world.get_resource_mut(ecs_key_meshlet_mesh_manager)) {
    (Some(meshlet_assets), Some(mesh_manager_ref)) =>
      ignore(
        mesh_manager_ref.modify(fn(mesh_manager) {
          source_world.for_each_component(ecs_key_meshlet_mesh3d, fn(
            entity,
            meshlet_mesh3d,
          ) {
            let meshlet_handle : @asset.Handle[MeshletMesh] = @asset.Handle::new(
              meshlet_mesh3d.id(),
            )
            let asset_ready = match asset_server {
              Some(server) => server.is_loaded_with_dependencies(meshlet_handle)
              None => true
            }
            if asset_ready {
              match
                (
                  meshlet_assets.get(meshlet_handle),
                  try! source_world.get_by_key(
                    entity, @pbr.ecs_key_mesh_material3d,
                  ),
                ) {
                (Some(meshlet_mesh), Some(mesh_material)) => {
                  let (root_bvh_node, aabb, bvh_depth) = mesh_manager.queue_upload_if_needed(
                    meshlet_mesh3d.id(),
                    meshlet_mesh,
                  )
                  let world_from_local = match
                    (try! source_world.get_by_key(
                      entity, @transform.ecs_key_global_transform,
                    )) {
                    Some(global_transform) => global_transform.affine()
                    None => @math.Affine3::identity()
                  }
                  let previous_world_from_local = match
                    (try! source_world.get_by_key(
                      entity, @pbr.ecs_key_previous_global_transform,
                    )) {
                    Some(previous_global_transform) =>
                      previous_global_transform.affine()
                    None => world_from_local
                  }
                  let render_layer_mask = match
                    (try! source_world.get_by_key(
                      entity, @camera_render_layers.ecs_key_render_layers,
                    )) {
                    Some(render_layers) => render_layers.mask()
                    None =>
                      @camera_render_layers.RenderLayers::RenderLayers().mask()
                  }
                  let not_shadow_caster = try! source_world.contains_by_key(
                    entity, @pbr.ecs_key_not_shadow_caster,
                  )
                  let not_shadow_receiver = try! source_world.contains_by_key(
                    entity, @pbr.ecs_key_not_shadow_receiver,
                  )
                  instance_manager.add_instance(
                    entity,
                    mesh_material.material.id(),
                    root_bvh_node,
                    aabb,
                    bvh_depth,
                    render_layer_mask~,
                    world_from_local~,
                    previous_world_from_local~,
                    not_shadow_caster~,
                    not_shadow_receiver~,
                    material_family=mesh_material.material_family,
                    material_extension=mesh_material.extended_material,
                  )
                }
                _ => ()
              }
            }
          })
        }),
      )
    _ => ()
  }
  world.insert_resource(ecs_key_meshlet_instance_manager, instance_manager)
}

///|
fn meshlet_instance_count_from_world(world : @ecs.World) -> Int {
  match world.get_resource(ecs_key_meshlet_instance_manager) {
    Some(instance_manager) => instance_manager.instance_count()
    None => 0
  }
}

///|
pub fn meshlet_view_size_from_camera(
  camera : @camera_camera.Camera,
) -> (Int, Int) {
  match camera.physical_viewport_size() {
    Some(size) => (size.x.max(1), size.y.max(1))
    None => (1, 1)
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
      MeshletViewMaterialsMainOpaquePass::MeshletViewMaterialsMainOpaquePass(),
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
    if has_normal_prepass || has_motion_vector_prepass || has_deferred_prepass {
      try! source_world.set_by_key(
        view_entity,
        ecs_key_meshlet_view_materials_prepass,
        MeshletViewMaterialsPrepass::MeshletViewMaterialsPrepass(),
      )
      try! source_world.set_by_key(
        view_entity,
        ecs_key_meshlet_view_materials_deferred_gbuffer_prepass,
        MeshletViewMaterialsDeferredGBufferPrepass::MeshletViewMaterialsDeferredGBufferPrepass(),
      )
    }
  }
}

///|
fn meshlet_prepare_resources_system(world : @ecs.World) -> Unit {
  let source_world = @render.render_source_world(world)
  let view_entities : Array[@core.Entity] = []
  source_world.for_each_component(@core_pipeline.ecs_key_msaa, fn(
    entity,
    _msaa,
  ) {
    view_entities.push(entity)
  })
  let instance_manager = world.get_resource(ecs_key_meshlet_instance_manager)
  let instance_count = match instance_manager {
    Some(manager) => manager.instance_count()
    None => 0
  }
  let max_bvh_depth = match instance_manager {
    Some(instance_manager) => instance_manager.max_bvh_depth()
    None => 0
  }
  match world.get_resource(ecs_key_meshlet_resource_manager) {
    Some(manager) => {
      prepare_meshlet_per_frame_resources(manager, instance_count)
      manager.clear_stale_prepared_view_resources(view_entities)
      for view_entity in view_entities {
        let (view_width, view_height) = match
          (try! source_world.get_by_key(
            view_entity, @camera_camera.ecs_key_camera,
          )) {
          Some(camera) => meshlet_view_size_from_camera(camera)
          None => (1, 1)
        }
        match instance_manager {
          Some(instance_manager) => {
            let view_render_layer_mask = match
              (try! source_world.get_by_key(
                view_entity, @camera_render_layers.ecs_key_render_layers,
              )) {
              Some(render_layers) => render_layers.mask()
              None => @camera_render_layers.RenderLayers::RenderLayers().mask()
            }
            ignore(
              instance_manager.prepare_view_instance_visibility(
                view_entity,
                view_render_layer_mask~,
              ),
            )
            @renderer.prepare_meshlet_view_instance_visibility_buffer(
              view_entity_bits=view_entity.to_bits(),
              instance_visibility=instance_manager.view_instance_visibility_bytes(
                view_entity,
              ),
            )
          }
          None => ()
        }
        ignore(
          prepare_meshlet_view_resources_for_view(
            manager,
            view_entity,
            instance_count,
            max_bvh_depth~,
            view_width~,
            view_height~,
          ),
        )
      }
    }
    _ => ()
  }
}

///|
fn meshlet_prepare_view_bind_groups_system(world : @ecs.World) -> Unit {
  let source_world = @render.render_source_world(world)
  let view_entities : Array[@core.Entity] = []
  source_world.for_each_component(@core_pipeline.ecs_key_msaa, fn(
    entity,
    _msaa,
  ) {
    view_entities.push(entity)
  })
  let instance_count = meshlet_instance_count_from_world(world)
  match world.get_resource(ecs_key_meshlet_resource_manager) {
    Some(manager) => {
      manager.clear_stale_prepared_view_bind_groups(view_entities)
      for view_entity in view_entities {
        ignore(
          prepare_meshlet_view_bind_groups_for_view(
            manager, view_entity, instance_count,
          ),
        )
      }
    }
    _ => ()
  }
}

///|
fn meshlet_queue_material_meshes_system(world : @ecs.World) -> Unit {
  match
    (
      world.get_resource(ecs_key_meshlet_instance_manager),
      world.get_resource(ecs_key_meshlet_mesh_manager),
    ) {
    (Some(instance_manager), Some(mesh_manager)) => {
      ignore(queue_material_meshlet_meshes(instance_manager))
      if instance_manager.instance_count() > 0 {
        ignore(
          upload_meshlet_mesh_manager_to_renderer(
            mesh_manager, instance_manager,
          ),
        )
      }
    }
    _ => ()
  }
}

///|
fn meshlet_refresh_plugin_state_system(world : @ecs.World) -> Unit {
  world.insert_resource(
    ecs_key_meshlet_plugin_state,
    MeshletPluginState::from_plugin(MeshletPlugin::MeshletPlugin()),
  )
}

///|
fn meshlet_material_reads_view_transmission_texture(
  material : @material.StandardMaterial,
) -> Bool {
  @pbr.standard_material_reads_view_transmission_texture(material)
}

///|
fn meshlet_default_opaque_renderer_method(
  source_world : @ecs.World,
) -> @material.OpaqueRendererMethod {
  match
    source_world.get_resource(@material.ecs_key_default_opaque_renderer_method) {
    Some(default_method) => default_method.renderer_method()
    None => @material.OpaqueRendererMethod::Forward
  }
}

///|
fn meshlet_standard_material_assets(
  source_world : @ecs.World,
) -> @asset.Assets[@material.StandardMaterial]? {
  let standard_material_assets_key : @ecs.ResourceKey[
    @asset.Assets[@material.StandardMaterial],
  ] = @asset.assets_resource_key()
  source_world.get_resource(standard_material_assets_key)
}

///|
fn meshlet_material_family_hash_string(hash : Int, value : String?) -> Int {
  match value {
    Some(text) => {
      let mut next = hash
      for index in 0..<text.length() {
        next = (next * 33 + text.code_unit_at(index).to_int()) % 8191
      }
      next
    }
    None => (hash * 33 + 17) % 8191
  }
}

///|
fn meshlet_material_pipeline_family_id(
  material_family : @material.Material3dFamily,
  extension : @material.ExtendedMaterialMetadata3d?,
) -> Int {
  let family_id = match material_family {
    @material.Material3dFamily::Standard => 0
    @material.Material3dFamily::ForwardDecal => 1
    @material.Material3dFamily::MeshletDebug => 2
  }
  guard extension is Some(extension) else { return family_id }
  let mut hash = 1 + extension.extension_tag % 8191
  hash = meshlet_material_family_hash_string(hash, extension.vertex_shader_path)
  hash = meshlet_material_family_hash_string(
    hash,
    extension.fragment_shader_path,
  )
  hash = meshlet_material_family_hash_string(
    hash,
    extension.prepass_vertex_shader_path,
  )
  hash = meshlet_material_family_hash_string(
    hash,
    extension.prepass_fragment_shader_path,
  )
  hash = meshlet_material_family_hash_string(
    hash,
    extension.deferred_vertex_shader_path,
  )
  hash = meshlet_material_family_hash_string(
    hash,
    extension.deferred_fragment_shader_path,
  )
  hash = meshlet_material_family_hash_string(
    hash,
    extension.meshlet_fragment_shader_path,
  )
  hash = meshlet_material_family_hash_string(
    hash,
    extension.meshlet_prepass_fragment_shader_path,
  )
  hash = meshlet_material_family_hash_string(
    hash,
    extension.meshlet_deferred_fragment_shader_path,
  )
  if hash <= 0 {
    family_id * 8192 + 1
  } else {
    family_id * 8192 + hash
  }
}

///|
fn meshlet_collect_standard_material_input(
  material_input : MeshletPreparedMaterialInput,
  assets : @asset.Assets[@material.StandardMaterial],
  scene_material : MeshletSceneMaterial,
  default_opaque_renderer_method : @material.OpaqueRendererMethod,
) -> MeshletPreparedMaterialInput {
  match assets.get(@asset.Handle::new(scene_material.material_asset_id)) {
    Some(material) => {
      let material = @pbr_render.render3d_apply_extended_material_metadata(
        material,
        scene_material.extension,
      )
      let material_properties = @pbr.render3d_material_properties_for_standard_material(
        material,
        scene_material.extension,
        default_opaque_renderer_method,
        false,
      )
      let mut next = material_input
        .with_opaque_render_method(
          @pbr.standard_material_opaque_render_method(
            material, default_opaque_renderer_method,
          ),
        )
        .with_alpha_mode(material.alpha_mode)
        .with_reads_view_transmission_texture(
          meshlet_material_reads_view_transmission_texture(material),
        )
      if material_properties.get_shader(@material.MESHLET_FRAGMENT_SHADER_LABEL)
        is Some(_) {
        next = next.with_meshlet_fragment_shader_override()
      }
      if material_properties.get_shader(
          @material.MESHLET_PREPASS_FRAGMENT_SHADER_LABEL,
        )
        is Some(_) {
        next = next.with_meshlet_prepass_fragment_shader_override()
      }
      if material_properties.get_shader(
          @material.MESHLET_DEFERRED_FRAGMENT_SHADER_LABEL,
        )
        is Some(_) {
        next = next.with_meshlet_deferred_fragment_shader_override()
      }
      next
    }
    None => material_input
  }
}

///|
fn meshlet_collect_material_inputs(
  source_world : @ecs.World,
  instance_manager : InstanceManager,
) -> Array[MeshletPreparedMaterialInput] {
  let material_inputs : Array[MeshletPreparedMaterialInput] = []
  let standard_material_assets = meshlet_standard_material_assets(source_world)
  let default_opaque_renderer_method = meshlet_default_opaque_renderer_method(
    source_world,
  )
  for scene_material in instance_manager.scene_materials() {
    let mut material_input = MeshletPreparedMaterialInput::new(
      scene_material.material_id,
      scene_material.material_asset_id,
    ).with_material_layout_id(
      meshlet_material_pipeline_family_id(
        scene_material.material_family,
        scene_material.extension,
      ),
    )
    match scene_material.material_family {
      @material.Material3dFamily::Standard =>
        match standard_material_assets {
          Some(assets) =>
            material_input = meshlet_collect_standard_material_input(
              material_input, assets, scene_material, default_opaque_renderer_method,
            )
          None => ()
        }
      @material.Material3dFamily::ForwardDecal => ()
      @material.Material3dFamily::MeshletDebug => ()
    }
    material_inputs.push(material_input)
  }
  material_inputs
}

///|
fn meshlet_tonemapping_mode_key(
  source_world : @ecs.World,
  entity : @core.Entity,
) -> Int {
  match (try! source_world.get_by_key(entity, @pbr.ecs_key_tonemapping)) {
    Some(tonemapping) =>
      match tonemapping {
        @pbr.Tonemapping::None => 0
        @pbr.Tonemapping::Reinhard => 1
        @pbr.Tonemapping::ReinhardLuminance => 2
        @pbr.Tonemapping::AcesFitted => 3
        @pbr.Tonemapping::AgX => 4
        @pbr.Tonemapping::SomewhatBoringDisplayTransform => 5
        @pbr.Tonemapping::TonyMcMapface => 6
        @pbr.Tonemapping::BlenderFilmic => 7
        @pbr.Tonemapping::PbrNeutral => 8
      }
    None => 0
  }
}

///|
fn meshlet_deband_dither_enabled(
  source_world : @ecs.World,
  entity : @core.Entity,
) -> Bool {
  match (try! source_world.get_by_key(entity, @pbr.ecs_key_deband_dither)) {
    Some(dither) => dither is @pbr.DebandDither::Enabled
    None => false
  }
}

///|
fn meshlet_projection_type_key(
  source_world : @ecs.World,
  entity : @core.Entity,
) -> Int {
  match (try! source_world.get_by_key(entity, @camera.ecs_key_projection)) {
    Some(projection) =>
      match projection {
        @camera.Projection::Perspective(_) => 1
        @camera.Projection::Orthographic(_) => 2
        @camera.Projection::Custom(_) => 3
      }
    None => 0
  }
}

///|
fn meshlet_shadow_filter_method_key(
  source_world : @ecs.World,
  entity : @core.Entity,
) -> Int {
  let shadow_filtering = match
    (try! source_world.get_by_key(entity, @pbr.ecs_key_shadow_filtering_method)) {
    Some(value) => value
    None => @pbr.ShadowFilteringMethod::default()
  }
  match shadow_filtering {
    @pbr.ShadowFilteringMethod::Hardware2x2 => 1
    @pbr.ShadowFilteringMethod::Gaussian => 2
    @pbr.ShadowFilteringMethod::Temporal => 3
  }
}

///|
fn meshlet_distance_fog_enabled(
  source_world : @ecs.World,
  entity : @core.Entity,
) -> Bool {
  (try! source_world.get_by_key(entity, @pbr.ecs_key_distance_fog)) is Some(_)
}

///|
fn meshlet_prepare_material_views_system(world : @ecs.World) -> Unit {
  let source_world = @render.render_source_world(world)
  let material_inputs = match
    world.get_resource(ecs_key_meshlet_instance_manager) {
    Some(instance_manager) =>
      meshlet_collect_material_inputs(source_world, instance_manager)
    None => []
  }
  let main_opaque_entities : Array[@core.Entity] = []
  source_world.for_each_component(
    ecs_key_meshlet_view_materials_main_opaque_pass,
    fn(entity, _main_opaque) { main_opaque_entities.push(entity) },
  )
  for entity in main_opaque_entities {
    let main_opaque = MeshletViewMaterialsMainOpaquePass::MeshletViewMaterialsMainOpaquePass()
    let has_normal_prepass = try! source_world.contains_by_key(
      entity, @core_pipeline.ecs_key_normal_prepass,
    )
    let has_hdr = try! source_world.contains_by_key(
      entity, @core_3d.ecs_key_hdr,
    )
    let has_depth_prepass = try! source_world.contains_by_key(
      entity, @core_pipeline.ecs_key_depth_prepass,
    )
    let has_motion_vector_prepass = try! source_world.contains_by_key(
      entity, @core_pipeline.ecs_key_motion_vector_prepass,
    )
    let has_deferred = try! source_world.contains_by_key(
      entity, @core_pipeline.ecs_key_deferred_prepass,
    )
    let has_temporal_jitter = try! source_world.contains_by_key(
      entity, @pbr.ecs_key_temporal_jitter,
    )
    let has_ssao = try! source_world.contains_by_key(
      entity, @pbr.ecs_key_screen_space_ambient_occlusion,
    )
    let has_environment_map = try! source_world.contains_by_key(
      entity, @pbr.ecs_key_environment_map_light,
    )
    let has_irradiance_volume = try! source_world.contains_by_key(
      entity, @pbr.ecs_key_irradiance_volume,
    )
    let projection_type = meshlet_projection_type_key(source_world, entity)
    let shadow_filter_method = meshlet_shadow_filter_method_key(
      source_world, entity,
    )
    let has_tonemapping_component = try! source_world.contains_by_key(
      entity, @pbr.ecs_key_tonemapping,
    )
    let tonemapping_mode = meshlet_tonemapping_mode_key(source_world, entity)
    let deband_dither = if !has_hdr {
      meshlet_deband_dither_enabled(source_world, entity)
    } else {
      false
    }
    let distance_fog = meshlet_distance_fog_enabled(source_world, entity)
    let view_key = MeshletViewMaterialPipelineKey::new(
      hdr=has_hdr,
      normal_prepass=has_normal_prepass,
      depth_prepass=has_depth_prepass,
      motion_vector_prepass=has_motion_vector_prepass,
      deferred_prepass=has_deferred,
      temporal_jitter=has_temporal_jitter,
      projection_type~,
      shadow_filter_method~,
      tonemap_in_shader=!has_hdr && has_tonemapping_component,
      tonemapping_mode~,
      deband_dither~,
      environment_map=has_environment_map,
      irradiance_volume=has_irradiance_volume,
      ssao=has_ssao,
      distance_fog~,
    )
    prepare_material_meshlet_meshes_main_opaque_pass_with_inputs(
      main_opaque,
      material_inputs,
      view_key~,
    )
    try! source_world.set_by_key(
      entity, ecs_key_meshlet_view_materials_main_opaque_pass, main_opaque,
    )
    let mut prepass = MeshletViewMaterialsPrepass::MeshletViewMaterialsPrepass()
    let mut deferred = MeshletViewMaterialsDeferredGBufferPrepass::MeshletViewMaterialsDeferredGBufferPrepass()
    let has_prepass = try! source_world.contains_by_key(
      entity, ecs_key_meshlet_view_materials_prepass,
    )
    let has_deferred_pass = try! source_world.contains_by_key(
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
    if has_deferred_pass {
      match
        (try! source_world.get_by_key(
          entity, ecs_key_meshlet_view_materials_deferred_gbuffer_prepass,
        )) {
        Some(value) => deferred = value
        None => ()
      }
    }
    if has_prepass || has_deferred_pass {
      prepare_material_meshlet_meshes_prepass_with_inputs(
        prepass,
        deferred,
        material_inputs,
        view_key~,
        deferred_enabled=has_deferred_pass,
      )
      if has_prepass {
        try! source_world.set_by_key(
          entity, ecs_key_meshlet_view_materials_prepass, prepass,
        )
      }
      if has_deferred_pass {
        try! source_world.set_by_key(
          entity, ecs_key_meshlet_view_materials_deferred_gbuffer_prepass, deferred,
        )
      }
    }
  }
}

///|
fn meshlet_visibility_buffer_raster_system(world : @ecs.World) -> Unit {
  if world.get_resource(ecs_key_meshlet_visibility_buffer_raster_state) is None {
    world.insert_resource(
      ecs_key_meshlet_visibility_buffer_raster_state,
      MeshletVisibilityBufferRasterState::MeshletVisibilityBufferRasterState(),
    )
  }
  let instance_count = meshlet_instance_count_from_world(world)
  let (
    view_count,
    shadow_view_count,
    material_depth_view_count,
    resource_max_bvh_depth,
  ) = match world.get_resource(ecs_key_meshlet_resource_manager) {
    Some(manager) =>
      (
        manager.prepared_not_shadow_view_count(),
        manager.prepared_shadow_view_count(),
        manager.prepared_material_depth_view_count(),
        manager.prepared_max_bvh_depth(),
      )
    None => (0, 0, 0, 0)
  }
  let (max_bvh_depth, rightmost_slot) = match
    (
      world.get_resource(ecs_key_meshlet_instance_manager),
      world.get_resource(ecs_key_meshlet_resource_manager),
    ) {
    (Some(instance_manager), Some(resource_manager)) =>
      (
        instance_manager.max_bvh_depth().max(resource_max_bvh_depth),
        resource_manager.cull_queue_rightmost_slot(),
      )
    (Some(instance_manager), None) =>
      (instance_manager.max_bvh_depth().max(resource_max_bvh_depth), 0)
    (None, Some(resource_manager)) =>
      (resource_max_bvh_depth, resource_manager.cull_queue_rightmost_slot())
    (None, None) => (resource_max_bvh_depth, 0)
  }
  let pipelines_ready = match world.get_resource(ecs_key_meshlet_pipelines) {
    Some(pipelines) => pipelines.get() is Some(_)
    None => false
  }
  match world.get_resource_mut(ecs_key_meshlet_visibility_buffer_raster_state) {
    Some(state) =>
      state.modify(fn(value) {
        value.enabled = meshlet_runtime_available()
        meshlet_visibility_buffer_raster(
          value,
          instance_count,
          view_count~,
          shadow_view_count~,
          max_bvh_depth~,
          rightmost_slot~,
          material_depth_view_count~,
          pipelines_ready~,
        )
      })
    _ => ()
  }
  if instance_count > 0 && meshlet_runtime_available() {
    match world.get_resource(ecs_key_meshlet_resource_manager) {
      Some(manager) => {
        ignore(manager.execute_prepared_clear_visibility_buffers())
        ignore(manager.execute_prepared_first_instance_culls())
        ignore(manager.execute_prepared_first_bvh_culls())
        ignore(manager.execute_prepared_first_meshlet_culls())
        ignore(manager.execute_prepared_visibility_buffer_software_raster())
        ignore(manager.execute_prepared_visibility_buffer_hardware_raster())
        ignore(manager.execute_prepared_fill_counts())
        ignore(manager.execute_prepared_downsample_depth())
        ignore(manager.execute_prepared_second_instance_culls())
        ignore(manager.execute_prepared_second_bvh_culls())
        ignore(manager.execute_prepared_second_meshlet_culls())
        ignore(manager.execute_prepared_visibility_buffer_software_raster())
        ignore(manager.execute_prepared_visibility_buffer_hardware_raster())
        ignore(manager.execute_prepared_fill_counts())
        ignore(manager.execute_prepared_resolve_depth())
        ignore(manager.execute_prepared_resolve_material_depth())
        ignore(manager.execute_prepared_downsample_depth())
      }
      None => ()
    }
  }
}

///|
fn meshlet_view_ready_for_material_shade_pass(
  manager : ResourceManager,
  view_entity : @core.Entity,
) -> (Bool, Bool) {
  match manager.prepared_view_resources(view_entity) {
    Some(resources) =>
      match manager.prepared_view_bind_groups(view_entity) {
        Some(bind_groups) =>
          (
            resources.has_material_depth(),
            bind_groups.has_material_shade_bind_group(),
          )
        None => (false, false)
      }
    None => (false, false)
  }
}

///|
fn meshlet_material_shade_layout_descriptor() -> @render_resource.BindGroupLayoutDescriptor {
  let fragment = @wgpu.SHADER_STAGE_FRAGMENT.to_uint()
  let entries : Array[@render_resource.BindGroupLayoutEntry] = []
  for binding in 0..<8 {
    entries.push(
      @render_resource.BindGroupLayoutEntry::new(
        binding,
        fragment,
        @render_resource.BindingType::BufferBinding(
          @render_resource.BufferBindingType::Storage(true),
          false,
          0UL,
        ),
      ),
    )
  }
  @render_resource.BindGroupLayoutDescriptor::new(
    "meshlet_mesh_material_shade_bind_group_layout", entries,
  )
}

///|
fn meshlet_empty_material_layout_descriptor(
  label : String,
) -> @render_resource.BindGroupLayoutDescriptor {
  @render_resource.BindGroupLayoutDescriptor::new(label, [])
}

///|
fn meshlet_shader_defs_with_material_pass(
  shader_defs : Array[@material.ShaderDefVal],
) -> Array[@material.ShaderDefVal] {
  let next = []
  for shader_def in shader_defs {
    next.push(shader_def)
  }
  next.push(@material.ShaderDefVal::Flag("MESHLET_MESH_MATERIAL_PASS"))
  next
}

///|
fn meshlet_view_material_mesh_pipeline_bits(
  view_key : MeshletViewMaterialPipelineKey,
) -> UInt64 {
  let mut bits = 0UL
  if view_key.tonemap_in_shader {
    bits = bits | 1UL
  }
  if view_key.deband_dither {
    bits = bits | 2UL
  }
  if view_key.depth_prepass {
    bits = bits | 4UL
  }
  if view_key.normal_prepass {
    bits = bits | 8UL
  }
  if view_key.deferred_prepass {
    bits = bits | 16UL
  }
  if view_key.motion_vector_prepass {
    bits = bits | 32UL
  }
  if view_key.environment_map {
    bits = bits | 128UL
  }
  if view_key.ssao {
    bits = bits | 256UL
  }
  if view_key.temporal_jitter {
    bits = bits | 1024UL
  }
  if view_key.irradiance_volume {
    bits = bits | 16384UL
  }
  if view_key.distance_fog {
    bits = bits | 1048576UL
  }
  bits = bits | ((view_key.tonemapping_mode.to_uint64() & 0xFUL) << 31)
  bits = bits | ((view_key.shadow_filter_method.to_uint64() & 0x3UL) << 35)
  bits = bits | ((view_key.projection_type.to_uint64() & 0x3UL) << 37)
  bits
}

///|
fn meshlet_material_pipeline_key_for_standard_material(
  properties : @material.MaterialProperties,
  view_key : MeshletViewMaterialPipelineKey,
) -> @material.ErasedMaterialPipelineKey {
  let mesh_bits = properties.mesh_pipeline_key_bits.bits() |
    meshlet_view_material_mesh_pipeline_bits(view_key) |
    @mesh.BaseMeshPipelineKey::from_primitive_topology(
      @mesh.Mesh3dPrimitiveTopology::TriangleList,
    ).bits()
  @material.ErasedMaterialPipelineKey::new(
    @material.ErasedMeshPipelineKey::new(mesh_bits, "MeshPipelineKey"),
    properties.material_key,
    "StandardMaterial",
  )
}

///|
fn meshlet_main_opaque_standard_material_descriptor(
  material : @material.StandardMaterial,
  extension : @material.ExtendedMaterialMetadata3d?,
  default_opaque_renderer_method : @material.OpaqueRendererMethod,
  view_key : MeshletViewMaterialPipelineKey,
) -> @material.RenderPipelineDescriptor? {
  let material = @pbr_render.render3d_apply_extended_material_metadata(
    material, extension,
  )
  let properties = @pbr.render3d_material_properties_for_standard_material(
    material, extension, default_opaque_renderer_method, false,
  )
  let layouts = @mesh.MeshVertexBufferLayouts::MeshVertexBufferLayouts()
  let fake_layout = layouts.insert(meshlet_fake_vertex_buffer_layout())
  let pipeline_key = meshlet_material_pipeline_key_for_standard_material(
    properties, view_key,
  )
  let descriptor = @pbr.PbrMaterialPipelineSpecializer::new(properties).specialize(
    pipeline_key, fake_layout,
  ) catch {
    _ => return None
  }
  guard descriptor.fragment is Some(fragment) else { return None }
  let shader_defs = meshlet_shader_defs_with_material_pass(fragment.shader_defs)
  let fragment_shader = match
    properties.get_shader(@material.MESHLET_FRAGMENT_SHADER_LABEL) {
    Some(shader) => Some(shader)
    None => Some(MESHLET_MESH_MATERIAL_SHADER_PATH)
  }
  let layout = descriptor.layout
  guard layout.length() >= 4 else { return None }
  layout[2] = meshlet_material_shade_layout_descriptor()
  Some(
    descriptor
    .with_layout(layout)
    .with_vertex(
      @material.VertexState::new(
        Some(MESHLET_MESH_MATERIAL_SHADER_PATH),
        shader_defs,
        descriptor.vertex.entry_point,
        [],
      ),
    )
    .with_fragment(
      Some(
        @material.FragmentState::new(
          fragment_shader,
          shader_defs,
          fragment.entry_point,
          fragment.targets,
        ),
      ),
    )
    .with_depth_stencil(
      Some(
        @material.DepthStencilState::new(
          @wgpu.TEXTURE_FORMAT_DEPTH16_UNORM,
          false,
          @wgpu.COMPARE_FUNCTION_EQUAL,
        ),
      ),
    ),
  )
}

///|
fn meshlet_main_opaque_debug_material_descriptor(
  default_opaque_renderer_method : @material.OpaqueRendererMethod,
  view_key : MeshletViewMaterialPipelineKey,
) -> @material.RenderPipelineDescriptor? {
  let descriptor = meshlet_main_opaque_standard_material_descriptor(
    @material.StandardMaterial::StandardMaterial(),
    None,
    default_opaque_renderer_method,
    view_key,
  )
  guard descriptor is Some(descriptor) else { return None }
  guard descriptor.fragment is Some(fragment) else { return None }
  let layout = descriptor.layout
  guard layout.length() >= 4 else { return None }
  layout[3] = meshlet_empty_material_layout_descriptor("MeshletDebugMaterial")
  Some(
    descriptor
    .with_label(Some("meshlet_debug_material"))
    .with_layout(layout)
    .with_fragment(
      Some(
        @material.FragmentState::new(
          Some(MESHLET_MESH_MATERIAL_SHADER_PATH),
          fragment.shader_defs,
          fragment.entry_point,
          fragment.targets,
        ),
      ),
    ),
  )
}

///|
fn meshlet_main_opaque_material_entry_for_draw_call(
  materials : MeshletViewMaterialsMainOpaquePass,
  draw_call : MeshletMaterialDrawCall,
) -> MeshletViewMaterialEntry? {
  for entry in materials.entries {
    if entry.material_id == draw_call.material_id &&
      entry.material_pipeline_id == draw_call.material_pipeline_id {
      return Some(entry)
    }
  }
  None
}

///|
fn meshlet_texture_id(texture : @asset.Handle[@asset.Image]?) -> Int {
  match texture {
    Some(handle) => handle.id()
    None => -1
  }
}

///|
fn meshlet_clamp01(value : Float) -> Float {
  if value < 0.0F {
    0.0F
  } else if value > 1.0F {
    1.0F
  } else {
    value
  }
}

///|
fn meshlet_maxf(left : Float, right : Float) -> Float {
  if left > right {
    left
  } else {
    right
  }
}

///|
fn meshlet_minf(left : Float, right : Float) -> Float {
  if left < right {
    left
  } else {
    right
  }
}

///|
fn meshlet_host_material_shade_draw_entry(
  material_id : Int,
  material_pipeline_id : UInt64,
  material : @material.StandardMaterial,
) -> @renderer.HostMeshletMaterialShadeDrawEntry {
  let texture_id = meshlet_texture_id(material.base_color_texture)
  let normal_texture_id = meshlet_texture_id(material.normal_map_texture)
  let emissive_texture_id = meshlet_texture_id(material.emissive_texture)
  let metallic_roughness_texture_id = meshlet_texture_id(
    material.metallic_roughness_texture,
  )
  let occlusion_texture_id = meshlet_texture_id(material.occlusion_texture)
  let depth_texture_id = meshlet_texture_id(material.depth_map)
  let anisotropy_texture_id = meshlet_texture_id(material.anisotropy_texture)
  let specular_tint_texture_id = meshlet_texture_id(
    material.specular_tint_texture,
  )
  let clearcoat_texture_id = meshlet_texture_id(material.clearcoat_texture)
  let clearcoat_roughness_texture_id = meshlet_texture_id(
    material.clearcoat_roughness_texture,
  )
  let clearcoat_normal_texture_id = meshlet_texture_id(
    material.clearcoat_normal_texture,
  )
  let anisotropy_strength = meshlet_clamp01(material.anisotropy_strength)
  let max_relief_mapping_search_steps = Float::from_double(
    material.parallax_mapping_method.max_steps().to_double(),
  )
  let clearcoat_reflectance = meshlet_maxf(
    0.0F,
    material.reflectance + material.clearcoat * 0.5F,
  )
  let clearcoat_roughness = meshlet_minf(
    material.perceptual_roughness,
    material.clearcoat_perceptual_roughness,
  )
  let draw_roughness = if material.clearcoat > 0.0F {
    clearcoat_roughness
  } else {
    material.perceptual_roughness
  }
  let payload = @pbr_render.render3d_build_mesh_gpu_draw_payload(
    -1,
    0,
    0,
    -1,
    0,
    -1,
    material,
    @transform.Transform::identity(),
    @transform.Transform::identity(),
    material.base_color.r,
    material.base_color.g,
    material.base_color.b,
    material.base_color.a,
    texture_id,
    normal_texture_id,
    emissive_texture_id,
    metallic_roughness_texture_id,
    occlusion_texture_id,
    depth_texture_id,
    anisotropy_texture_id,
    specular_tint_texture_id,
    clearcoat_texture_id,
    clearcoat_roughness_texture_id,
    clearcoat_normal_texture_id,
    draw_roughness,
    clearcoat_reflectance,
    meshlet_clamp01(material.diffuse_transmission),
    meshlet_clamp01(material.specular_transmission),
    meshlet_maxf(0.0F, material.thickness),
    meshlet_maxf(1.0F, material.ior),
    -1,
    0.0F,
    0.0F,
    -1,
    0.0F,
    0.0F,
    -1,
    -1,
    0.0F,
    @math.Quat::identity(),
    material.specular_tint,
    anisotropy_strength,
    max_relief_mapping_search_steps,
    0U,
    0,
    material_pipeline_id=Some(
      @render_resource.CachedRenderPipelineId::new(material_pipeline_id),
    ),
  )
  @renderer.host_meshlet_material_shade_draw_entry(
    material_id~,
    material_pipeline_id~,
    draw_entry=@pbr_render.render3d_host_main_pass_draw_entry(payload),
  )
}

///|
fn meshlet_main_opaque_material_shade_draws(
  materials : MeshletViewMaterialsMainOpaquePass,
  instance_manager : InstanceManager,
  standard_material_assets : @asset.Assets[@material.StandardMaterial]?,
  default_opaque_renderer_method : @material.OpaqueRendererMethod,
  has_material_depth : Bool,
  has_material_shade_bind_group : Bool,
) -> Array[@renderer.HostMeshletMaterialShadeDrawEntry] {
  let draw_calls = meshlet_main_opaque_pass_draw_calls(
    materials,
    instance_manager,
    has_material_depth~,
    has_material_shade_bind_group~,
  )
  let draws : Array[@renderer.HostMeshletMaterialShadeDrawEntry] = []
  for draw_call in draw_calls {
    guard instance_manager.material_asset_id_for_id(draw_call.material_id)
      is Some(material_asset_id) else {
      continue
    }
    guard instance_manager.material_family_for_id(draw_call.material_id)
      is Some(material_family) else {
      continue
    }
    guard meshlet_main_opaque_material_entry_for_draw_call(materials, draw_call)
      is Some(material_entry) else {
      continue
    }
    let (material, descriptor) = match material_family {
      @material.Material3dFamily::Standard => {
        guard standard_material_assets is Some(assets) else { continue }
        guard assets.get(@asset.Handle::new(material_asset_id))
          is Some(base_material) else {
          continue
        }
        let material_extension = instance_manager.material_extension_for_id(
          draw_call.material_id,
        )
        let material = @pbr_render.render3d_apply_extended_material_metadata(
          base_material, material_extension,
        )
        guard meshlet_main_opaque_standard_material_descriptor(
            base_material,
            material_extension,
            default_opaque_renderer_method,
            material_entry.descriptor.view_key,
          )
          is Some(descriptor) else {
          continue
        }
        (material, descriptor)
      }
      @material.Material3dFamily::ForwardDecal => continue
      @material.Material3dFamily::MeshletDebug => {
        guard meshlet_main_opaque_debug_material_descriptor(
            default_opaque_renderer_method,
            material_entry.descriptor.view_key,
          )
          is Some(descriptor) else {
          continue
        }
        (@material.StandardMaterial::StandardMaterial(), descriptor)
      }
    }
    let pipeline_id = draw_call.material_pipeline_id.to_uint64()
    @renderer.register_mesh3d_material_pipeline_descriptor(
      material_pipeline_id=pipeline_id,
      descriptor~,
    )
    draws.push(
      meshlet_host_material_shade_draw_entry(
        draw_call.material_id,
        pipeline_id,
        material,
      ),
    )
  }
  draws
}

///|
fn meshlet_prepass_system(world : @ecs.World) -> Unit {
  let source_world = @render.render_source_world(world)
  let mut draw_count = 0
  match
    (
      world.get_resource(ecs_key_meshlet_instance_manager),
      world.get_resource(ecs_key_meshlet_resource_manager),
    ) {
    (Some(instance_manager), Some(resource_manager)) =>
      source_world.for_each_component(ecs_key_meshlet_view_materials_prepass, fn(
        view_entity,
        materials,
      ) {
        let (has_material_depth, has_material_shade_bind_group) = meshlet_view_ready_for_material_shade_pass(
          resource_manager, view_entity,
        )
        draw_count = draw_count +
          meshlet_prepass_materials(
            materials,
            instance_manager,
            has_material_depth~,
            has_material_shade_bind_group~,
          )
      })
    _ => ()
  }
  ignore(meshlet_prepass(draw_count))
}

///|
fn meshlet_deferred_gbuffer_prepass_system(world : @ecs.World) -> Unit {
  let source_world = @render.render_source_world(world)
  let mut draw_count = 0
  match
    (
      world.get_resource(ecs_key_meshlet_instance_manager),
      world.get_resource(ecs_key_meshlet_resource_manager),
    ) {
    (Some(instance_manager), Some(resource_manager)) =>
      source_world.for_each_component(
        ecs_key_meshlet_view_materials_deferred_gbuffer_prepass,
        fn(view_entity, materials) {
          let (has_material_depth, has_material_shade_bind_group) = meshlet_view_ready_for_material_shade_pass(
            resource_manager, view_entity,
          )
          draw_count = draw_count +
            meshlet_deferred_gbuffer_prepass_materials(
              materials,
              instance_manager,
              has_material_depth~,
              has_material_shade_bind_group~,
            )
        },
      )
    _ => ()
  }
  ignore(meshlet_deferred_gbuffer_prepass(draw_count))
}

///|
fn meshlet_main_opaque_pass_system(world : @ecs.World) -> Unit {
  let source_world = @render.render_source_world(world)
  let mut draw_count = 0
  let standard_material_assets = meshlet_standard_material_assets(source_world)
  let default_opaque_renderer_method = meshlet_default_opaque_renderer_method(
    source_world,
  )
  match
    (
      world.get_resource(ecs_key_meshlet_instance_manager),
      world.get_resource(ecs_key_meshlet_resource_manager),
    ) {
    (Some(instance_manager), Some(resource_manager)) =>
      source_world.for_each_component(
        ecs_key_meshlet_view_materials_main_opaque_pass,
        fn(view_entity, materials) {
          let (has_material_depth, has_material_shade_bind_group) = meshlet_view_ready_for_material_shade_pass(
            resource_manager, view_entity,
          )
          let draws = meshlet_main_opaque_material_shade_draws(
            materials, instance_manager, standard_material_assets, default_opaque_renderer_method,
            has_material_depth, has_material_shade_bind_group,
          )
          draw_count = draw_count + draws.length()
          if draws.length() > 0 {
            ignore(
              @renderer.execute_meshlet_main_opaque_material_shade(
                view_entity_bits=view_entity.to_bits(),
                draws~,
              ),
            )
          }
        },
      )
    _ => ()
  }
  ignore(meshlet_main_opaque_pass(draw_count))
}

///|
fn meshlet_ensure_render_sub_app_resources(
  world : @ecs.World,
  plugin : MeshletPlugin,
) -> Unit {
  let plugin_state = MeshletPluginState::from_plugin(plugin)
  world.insert_resource(ecs_key_meshlet_plugin_state, plugin_state)
  if world.get_resource(ecs_key_meshlet_instance_manager) is None {
    world.insert_resource(
      ecs_key_meshlet_instance_manager,
      InstanceManager::InstanceManager(),
    )
  }
  if world.get_resource(ecs_key_meshlet_resource_manager) is None {
    world.insert_resource(
      ecs_key_meshlet_resource_manager,
      ResourceManager::new(plugin.cluster_buffer_slots()),
    )
  }
  if world.get_resource(ecs_key_meshlet_pipelines) is None {
    world.insert_resource(
      ecs_key_meshlet_pipelines,
      init_meshlet_pipelines(-1, -1, -1),
    )
  }
  if world.get_resource(ecs_key_meshlet_mesh_manager) is None {
    world.insert_resource(
      ecs_key_meshlet_mesh_manager,
      MeshletMeshManager::MeshletMeshManager(),
    )
  }
  if world.get_resource(ecs_key_meshlet_visibility_buffer_raster_state) is None {
    world.insert_resource(
      ecs_key_meshlet_visibility_buffer_raster_state,
      MeshletVisibilityBufferRasterState::MeshletVisibilityBufferRasterState(),
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
    @app.system(meshlet_refresh_plugin_state_system).in_set(
      meshlet_render3d_set_extract,
    ),
  )
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
      meshlet_render3d_set_create_views,
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
  .configure_set(stage, meshlet_render3d_set_create_views, before=[
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
pub fn register_meshlet_mesh3d_required_components(
  world : @ecs.World,
) -> Unit raise @ecs.RequiredComponentsError {
  world.register_required_components_with(
    ecs_key_meshlet_mesh3d,
    @transform.ecs_key_transform,
    fn() { @transform.Transform::identity() },
  )
  world.register_required_components_with(
    ecs_key_meshlet_mesh3d,
    @pbr.ecs_key_previous_global_transform,
    fn() {
      @pbr_prepass.PreviousGlobalTransform::from_global_transform(
        @transform.GlobalTransform::identity(),
      )
    },
  )
  world.register_required_components_with(
    ecs_key_meshlet_mesh3d,
    @visibility.ecs_key_visibility,
    fn() { @visibility.Visibility::Inherited },
  )
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
    try! register_meshlet_mesh3d_required_components(next.world())
    next = @render.with_render_app(next, fn(sub_app : @app.SubApp[@ecs.World]) {
      meshlet_configure_render_sub_app(sub_app, plugin)
    })
  }
  next
}

///|
pub impl @app.Plugin for MeshletPlugin with fn name(_self) {
  MESHLET_PLUGIN_NAME
}

///|
pub impl @app.Plugin for MeshletPlugin with fn build(self, app) {
  register_embedded_wgsl_sources()
  meshlet_plugin_with(
    init_meshlet_debug_material_asset(init_meshlet_mesh_asset(app)),
    self,
  )
}

///|
pub struct MeshletPluginState {
  runtime_status : MeshletRuntimeStatus
  missing_required_features : UInt64
  missing_native_subgroup_barrier : Bool
  missing_native_r64uint_storage_texture_api : Bool
  missing_native_immediates : Bool
  adapter_supports_mesh_shader : Bool
}

///|
pub fn MeshletPluginState::MeshletPluginState() -> MeshletPluginState {
  MeshletPluginState::from_plugin(MeshletPlugin::MeshletPlugin())
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
    missing_native_r64uint_storage_texture_api: @renderer.meshlet_missing_native_r64uint_storage_texture_api(),
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
pub impl @ecs.Component for MeshletMesh3d with fn component() {
  ecs_key_meshlet_mesh3d
}
