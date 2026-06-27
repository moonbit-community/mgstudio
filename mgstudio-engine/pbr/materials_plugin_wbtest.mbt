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
test "render3d: materials startup initializes bevy material render resources" {
  let world = @ecs.World::new()

  init_materials_resources(world)

  debug_inspect(
    world.get_resource(ecs_key_entity_specialization_ticks) is Some(_),
    content="true",
  )
  debug_inspect(
    world.get_resource(ecs_key_specialized_material_pipeline_cache) is Some(_),
    content="true",
  )
  debug_inspect(
    world.get_resource(@render_visibility.DirtySpecializations::resource())
    is Some(_),
    content="true",
  )
  debug_inspect(
    world.get_resource(@pbr_render.LightKeyCache::resource()) is Some(_),
    content="true",
  )
  debug_inspect(
    world.get_resource(
      @pbr_render.SpecializedShadowMaterialPipelineCache::resource(),
    )
    is Some(_),
    content="true",
  )
  debug_inspect(
    world.get_resource(ecs_key_render_material_instances) is Some(_),
    content="true",
  )
  debug_inspect(
    world.get_resource(ecs_key_material_bind_group_allocators) is Some(_),
    content="true",
  )
  debug_inspect(
    world.get_resource(PendingMeshMaterialQueues::resource()) is Some(_),
    content="true",
  )
  debug_inspect(
    world.get_resource(@pbr_render.PendingShadowQueues::resource()) is Some(_),
    content="true",
  )
  debug_inspect(
    world.get_resource(Render3dShadowPhasesData::resource()) is Some(_),
    content="true",
  )
  debug_inspect(
    get_default_opaque_renderer_method_resource(world).is_present(),
    content="true",
  )
}

///|
test "render3d: materials startup preserves existing material render resources" {
  let world = @ecs.World::new()
  let entity_ticks = EntitySpecializationTicks::EntitySpecializationTicks()
  let entity = @core.Entity::new(12, 0)
  entity_ticks.insert(entity, EntitySpecializationTickPair::new(5, 6))
  world.insert_resource(ecs_key_entity_specialization_ticks, entity_ticks)

  init_materials_resources(world)

  match world.get_resource(ecs_key_entity_specialization_ticks) {
    Some(ticks) =>
      debug_inspect(
        ticks.get(entity).map(fn(pair) { pair.system_tick() }),
        content="Some(5)",
      )
    None => debug_inspect(false, content="true")
  }
}

///|
test "render3d: materials startup preserves pending queue resources" {
  let world = @ecs.World::new()
  let view = @render_view.RetainedViewEntity::new(@core.Entity::new(10, 1))
  let main_entity = @render.MainEntity::new(@core.Entity::new(11, 1))
  let mesh_queues = PendingMeshMaterialQueues::PendingMeshMaterialQueues()
  mesh_queues
  .queues()
  .push_current(
    view,
    @core.Entity::new(1, 1),
    @render.MainEntity::new(@core.Entity::new(2, 1)),
  )
  let shadow_queues = @pbr_render.PendingShadowQueues::PendingShadowQueues()
  shadow_queues
  .queues()
  .push_current(
    view,
    @core.Entity::new(3, 1),
    @render.MainEntity::new(@core.Entity::new(4, 1)),
  )
  world.insert_resource(PendingMeshMaterialQueues::resource(), mesh_queues)
  world.insert_resource(
    @pbr_render.PendingShadowQueues::resource(),
    shadow_queues,
  )
  let shadow_phases = Render3dShadowPhasesData::Render3dShadowPhasesData()
  shadow_phases
  .view_or_insert(view)
  .add(
    Render3dShadowBatchSetKeyData::new(
      @material.CachedRenderPipelineId::new(901UL),
      @material.DrawFunctionId::new(9U),
      None,
      @render_mesh.MeshSlabs::new(4),
    ),
    Render3dShadowBinKeyData::new(5),
    (@core.Entity::new(12, 1), main_entity),
    7U,
    Render3dShadowBinnedRenderPhaseType::mesh(
      true,
      @render_batching.GpuPreprocessingSupport::GpuPreprocessingSupport(),
    ),
  )
  world.insert_resource(Render3dShadowPhasesData::resource(), shadow_phases)

  init_materials_resources(world)

  match world.get_resource(PendingMeshMaterialQueues::resource()) {
    Some(queues) =>
      debug_inspect(queues.queues().current_len(view), content="1")
    None => debug_inspect(false, content="true")
  }
  match world.get_resource(@pbr_render.PendingShadowQueues::resource()) {
    Some(queues) =>
      debug_inspect(queues.queues().current_len(view), content="1")
    None => debug_inspect(false, content="true")
  }
  match world.get_resource(Render3dShadowPhasesData::resource()) {
    Some(phases) => {
      debug_inspect(phases.len(), content="1")
      match phases.get(view) {
        Some(phase) => {
          debug_inspect(phase.len(), content="1")
          debug_inspect(
            phase.input_uniform_index(main_entity),
            content="Some(7)",
          )
        }
        None => debug_inspect(false, content="true")
      }
    }
    None => debug_inspect(false, content="true")
  }
}

///|
test "render3d: pending mesh material queues prepare live views and expire stale views" {
  let live_view = @render_view.RetainedViewEntity::new(@core.Entity::new(30, 1))
  let stale_view = @render_view.RetainedViewEntity::new(
    @core.Entity::new(31, 1),
  )
  let queues = PendingMeshMaterialQueues::PendingMeshMaterialQueues()
  queues
  .queues()
  .push_current(
    live_view,
    @core.Entity::new(32, 1),
    @render.MainEntity::new(@core.Entity::new(33, 1)),
  )
  queues
  .queues()
  .push_current(
    stale_view,
    @core.Entity::new(34, 1),
    @render.MainEntity::new(@core.Entity::new(35, 1)),
  )

  ignore(queues.prepare_for_new_frame(live_view))
  let live_views : @hashset.HashSet[@render_view.RetainedViewEntity] = @hashset.HashSet([],
  )
  live_views.add(live_view)
  queues.expire_stale_views(live_views)

  debug_inspect(queues.current_len(live_view), content="0")
  debug_inspect(queues.prev_len(live_view), content="1")
  debug_inspect(queues.current_len(stale_view), content="0")
  debug_inspect(queues.prev_len(stale_view), content="0")
  debug_inspect(queues.view_len(), content="1")
}

///|
fn material_test_pair_contains(
  pairs : Array[(@core.Entity, @render.MainEntity)],
  render_entity : @core.Entity,
  main_entity : @core.Entity,
) -> Bool {
  for pair in pairs {
    if pair.0 == render_entity && pair.1 == @render.MainEntity::new(main_entity) {
      return true
    }
  }
  false
}

///|
fn material_test_base_specialize(
  _world : @ecs.World,
  _key : @material.ErasedMaterialPipelineKey,
  layout : @material.MaterialMeshVertexLayout,
  _properties : @material.MaterialProperties,
) -> @material.CachedRenderPipelineId raise @material.SpecializedMeshPipelineError {
  if layout.index() < 0 {
    raise @material.missing_vertex_attribute_error("layout")
  }
  @material.CachedRenderPipelineId::new(901UL)
}

///|
fn material_test_camera_payload() -> Camera3dViewPayload {
  Camera3dViewPayload::{
    decal_config: None,
    deferred_config: None,
    distance_fog: None,
    auto_exposure: None,
    volumetric_fog: None,
    atmosphere: None,
    atmosphere_settings: None,
    camera: @camera_camera.Camera::Camera(),
    depth_texture_usages: Camera3dDepthTextureUsage::Camera3dDepthTextureUsage(),
    projection: Projection::default(),
    sub_camera_view: None,
    oit_settings: None,
    screen_space_transmission: None,
    bloom: None,
    tonemapping: None,
    deband_dither: None,
    chromatic_aberration: None,
    contrast_adaptive_sharpening: None,
    custom_post_process3d: None,
    vignette: None,
    motion_blur: None,
    exposure: None,
    color_grading: None,
    environment_map_light: None,
    generated_environment_map_light: None,
    atmosphere_environment_map_light: None,
    has_environment_light_probes: false,
    irradiance_volume: None,
    screen_space_ambient_occlusion: None,
    screen_space_reflections: None,
    contact_shadows: None,
    depth_prepass_enabled: false,
    normal_prepass_enabled: false,
    deferred_prepass_enabled: false,
    no_indirect_drawing: false,
    gpu_occlusion_culling_enabled: false,
    hdr_enabled: false,
    fxaa: None,
    temporal_jitter: None,
    temporal_anti_aliasing: None,
    shadow_filtering_method: None,
    motion_vector_prepass_enabled: false,
    msaa: None,
    transform: @transform.Transform::Transform(),
    previous_transform: @transform.Transform::Transform(),
    previous_clip_from_world: None,
    target_id: 0,
    target_size: @math.IVec2::new(1280, 720),
    scale_factor: 1.0F,
    layers: @camera_render_layers.RenderLayers::RenderLayers(),
    has_no_cpu_culling: false,
    invert_culling: false,
  }
}

///|
fn material_test_extracted_mesh_payload(
  mesh_id : Int,
  material_properties : @material.MaterialProperties,
) -> Mesh3dExtractedPayload {
  let transform = @transform.Transform::identity()
  let world_from_local = @math.Affine3::identity()
  Mesh3dExtractedPayload::{
    mesh_handle: @asset.Handle::new(mesh_id),
    mesh_id,
    mesh_topology_kind: 0,
    mesh_is_indexed: true,
    mesh_preprocess_static: None,
    world_from_local,
    previous_world_from_local: world_from_local,
    transform,
    previous_transform: transform,
    visibility_range: None,
    aabb: None,
    aabb_center_world: None,
    material: @material.StandardMaterial::StandardMaterial(),
    material_extension: None,
    material_properties,
    material_bind_group_data: @render_resource.MaterialBindGroupResolvedData::MaterialBindGroupResolvedData(),
    material_pipeline_id: None,
    lightmap: None,
    is_forward_decal: false,
    forward_decal_material_ext: None,
    clustered_decal: None,
    has_not_shadow_caster: false,
    has_not_shadow_receiver: false,
    has_transmitted_shadow_receiver: false,
    has_no_frustum_culling: false,
    has_no_cpu_culling: false,
    layers: @camera_render_layers.RenderLayers::RenderLayers(),
    has_no_wireframe: false,
    wireframe_asset_id: None,
    wireframe_material: None,
    wireframe_color: None,
    wireframe_line_width: None,
    wireframe_topology: None,
    skinning_key_hi: -1,
    has_previous_skin: false,
    morph_weights_index: -1,
    previous_morph_weights_index: -1,
    morph_targets_texture_id: -1,
    instance_vertex_buffer_id: -1,
    motion_vector_enabled: false,
  }
}

///|
test "render3d: extract render visible entities mirrors camera visible Mesh3d pairs" {
  let world = @ecs.World::new()
  let main_camera = world.spawn()
  let render_camera = world.spawn()
  let main_mesh = world.spawn()
  let render_mesh = world.spawn()
  try! world.set_by_key(main_camera, ecs_key_camera3d, Camera3d::Camera3d())
  try! world.set_by_key(
    main_camera,
    @camera_camera.ecs_key_camera,
    @camera_camera.Camera::Camera(),
  )
  try! world.set_by_key(
    main_camera,
    @render.ecs_key_render_entity,
    @render.RenderEntity::new(render_camera),
  )
  try! world.set_by_key(
    main_mesh,
    @render.ecs_key_render_entity,
    @render.RenderEntity::new(render_mesh),
  )
  let visible = @camera_camera.VisibleEntities::VisibleEntities()
  visible.push(main_mesh, @mesh.ecs_key_mesh3d.id())
  try! world.set_by_key(
    main_camera, @camera_camera.ecs_key_visible_entities, visible,
  )

  render3d_extract_render_visible_entities(world, world)

  match
    (try! world.get_by_key(
      render_camera, @render_visibility.ecs_key_render_visible_entities,
    )) {
    Some(render_visible) =>
      match render_visible.get(render3d_mesh_visibility_class()) {
        Some(mesh_visible) => {
          debug_inspect(mesh_visible.visible_len(), content="1")
          debug_inspect(mesh_visible.added_entities().length(), content="1")
          debug_inspect(mesh_visible.removed_entities().length(), content="0")
          debug_inspect(
            mesh_visible.entity_pair_is_visible(
              render_mesh,
              @render.MainEntity::new(main_mesh),
            ),
            content="true",
          )
        }
        None => debug_inspect(false, content="true")
      }
    None => debug_inspect(false, content="true")
  }

  let no_visible_meshes = @camera_camera.VisibleEntities::VisibleEntities()
  try! world.set_by_key(
    main_camera, @camera_camera.ecs_key_visible_entities, no_visible_meshes,
  )
  render3d_extract_render_visible_entities(world, world)

  match
    (try! world.get_by_key(
      render_camera, @render_visibility.ecs_key_render_visible_entities,
    )) {
    Some(render_visible) =>
      match render_visible.get(render3d_mesh_visibility_class()) {
        Some(mesh_visible) => {
          debug_inspect(mesh_visible.visible_len(), content="0")
          debug_inspect(mesh_visible.added_entities().length(), content="0")
          debug_inspect(mesh_visible.removed_entities().length(), content="1")
        }
        None => debug_inspect(false, content="true")
      }
    None => debug_inspect(false, content="true")
  }
}

///|
test "render3d: material specialization candidates come from visible dirty and pending meshes" {
  let world = @ecs.World::new()
  let main_view = @core.Entity::new(41, 1)
  let render_view = world.spawn()
  let unchanged_main = @core.Entity::new(42, 1)
  let unchanged_render = @core.Entity::new(43, 1)
  let changed_main = @core.Entity::new(44, 1)
  let changed_render = @core.Entity::new(45, 1)
  let pending_main = @core.Entity::new(46, 1)
  let pending_render = @core.Entity::new(47, 1)
  let added_main = @core.Entity::new(48, 1)
  let added_render = @core.Entity::new(49, 1)
  let visible_entities = @render_visibility.RenderVisibleEntities::RenderVisibleEntities()
  let visible_class = visible_entities.class_or_insert(
    render3d_mesh_visibility_class(),
  )
  visible_class.prepare_for_new_frame()
  visible_class.update_cpu_culled_entities([
    (unchanged_render, @render.MainEntity::new(unchanged_main)),
    (changed_render, @render.MainEntity::new(changed_main)),
    (pending_render, @render.MainEntity::new(pending_main)),
  ])
  visible_class.prepare_for_new_frame()
  visible_class.update_cpu_culled_entities([
    (unchanged_render, @render.MainEntity::new(unchanged_main)),
    (changed_render, @render.MainEntity::new(changed_main)),
    (pending_render, @render.MainEntity::new(pending_main)),
    (added_render, @render.MainEntity::new(added_main)),
  ])
  visible_class.sort_added_entities()
  try! world.set_by_key(
    render_view, @render_visibility.ecs_key_render_visible_entities, visible_entities,
  )
  let dirty_specializations = @render_visibility.DirtySpecializations::DirtySpecializations()
  dirty_specializations.insert_changed(@render.MainEntity::new(changed_main))
  let pending_queues = PendingMeshMaterialQueues::PendingMeshMaterialQueues()
  let retained_view = @render_view.RetainedViewEntity::new(main_view)
  pending_queues
  .queues()
  .push_current(
    retained_view,
    pending_render,
    @render.MainEntity::new(pending_main),
  )
  ignore(pending_queues.prepare_for_new_frame(retained_view))

  let candidates = render3d_material_specialization_candidates(
    world, render_view, retained_view, dirty_specializations, pending_queues,
  )

  debug_inspect(candidates.length(), content="3")
  debug_inspect(
    material_test_pair_contains(candidates, added_render, added_main),
    content="true",
  )
  debug_inspect(
    material_test_pair_contains(candidates, changed_render, changed_main),
    content="true",
  )
  debug_inspect(
    material_test_pair_contains(candidates, pending_render, pending_main),
    content="true",
  )
  debug_inspect(
    material_test_pair_contains(candidates, unchanged_render, unchanged_main),
    content="false",
  )
}

///|
test "render3d: shadow specialization candidates come from visible dirty and pending meshes" {
  let world = @ecs.World::new()
  let main_view = @core.Entity::new(451, 1)
  let shadow_light = world.spawn()
  let shadow_visible_view = @render_view.RetainedViewEntity::new(main_view)
  let retained_view = @render_view.RetainedViewEntity::new(
    main_view,
    auxiliary_entity=Some(@core.Entity::new(460, 1)),
    subview_index=7,
  )
  let unchanged_main = @core.Entity::new(452, 1)
  let unchanged_render = @core.Entity::new(453, 1)
  let changed_main = @core.Entity::new(454, 1)
  let changed_render = @core.Entity::new(455, 1)
  let pending_main = @core.Entity::new(456, 1)
  let pending_render = @core.Entity::new(457, 1)
  let added_main = @core.Entity::new(458, 1)
  let added_render = @core.Entity::new(459, 1)
  let shadow_map_visible_entities = @render_visibility.RenderShadowMapVisibleEntities::RenderShadowMapVisibleEntities()
  let visible_entities = shadow_map_visible_entities.subview_or_insert(
    shadow_visible_view,
  )
  let visible_class = visible_entities.class_or_insert(
    render3d_mesh_visibility_class(),
  )
  visible_class.prepare_for_new_frame()
  visible_class.update_cpu_culled_entities([
    (unchanged_render, @render.MainEntity::new(unchanged_main)),
    (changed_render, @render.MainEntity::new(changed_main)),
    (pending_render, @render.MainEntity::new(pending_main)),
  ])
  visible_class.prepare_for_new_frame()
  visible_class.update_cpu_culled_entities([
    (unchanged_render, @render.MainEntity::new(unchanged_main)),
    (changed_render, @render.MainEntity::new(changed_main)),
    (pending_render, @render.MainEntity::new(pending_main)),
    (added_render, @render.MainEntity::new(added_main)),
  ])
  visible_class.sort_added_entities()
  try! world.set_by_key(
    shadow_light, @render_visibility.ecs_key_render_shadow_map_visible_entities,
    shadow_map_visible_entities,
  )
  let dirty_specializations = @render_visibility.DirtySpecializations::DirtySpecializations()
  dirty_specializations.insert_changed(@render.MainEntity::new(changed_main))
  let pending_queues = @pbr_render.PendingShadowQueues::PendingShadowQueues()
  pending_queues
  .queues()
  .push_current(
    retained_view,
    pending_render,
    @render.MainEntity::new(pending_main),
  )
  ignore(pending_queues.queues().prepare_for_new_frame(retained_view))

  let candidates = render3d_shadow_specialization_candidates_for_light(
    world,
    Render3dLightEntity::Spot(light_entity=shadow_light),
    retained_view,
    dirty_specializations,
    pending_queues,
  )

  debug_inspect(candidates.length(), content="3")
  debug_inspect(
    material_test_pair_contains(candidates, added_render, added_main),
    content="true",
  )
  debug_inspect(
    material_test_pair_contains(candidates, changed_render, changed_main),
    content="true",
  )
  debug_inspect(
    material_test_pair_contains(candidates, pending_render, pending_main),
    content="true",
  )
  debug_inspect(
    material_test_pair_contains(candidates, unchanged_render, unchanged_main),
    content="false",
  )
}

///|
test "render3d: missing material specialization mesh returns to pending queue" {
  let world = @ecs.World::new()
  let retained_view = @render_view.RetainedViewEntity::new(
    @core.Entity::new(50, 1),
  )
  let render_entity = @core.Entity::new(51, 1)
  let main_entity = @render.MainEntity::new(@core.Entity::new(52, 1))
  let pending_queues = PendingMeshMaterialQueues::PendingMeshMaterialQueues()
  ignore(pending_queues.prepare_for_new_frame(retained_view))
  world.insert_resource(PendingMeshMaterialQueues::resource(), pending_queues)

  render3d_enqueue_pending_mesh_material(
    world, retained_view, render_entity, main_entity,
  )

  match world.get_resource(PendingMeshMaterialQueues::resource()) {
    Some(queues) => {
      debug_inspect(queues.current_len(retained_view), content="1")
      debug_inspect(queues.prev_len(retained_view), content="0")
    }
    None => debug_inspect(false, content="true")
  }
}

///|
test "render3d: material specialization readiness follows Bevy resources" {
  let world = @ecs.World::new()
  let retained_view = @render_view.RetainedViewEntity::new(
    @core.Entity::new(53, 1),
  )
  let render_entity = @core.Entity::new(54, 1)
  let missing_material = @render.MainEntity::new(@core.Entity::new(55, 1))
  let missing_mesh = @render.MainEntity::new(@core.Entity::new(56, 1))
  let ready = @render.MainEntity::new(@core.Entity::new(57, 1))
  let pending_queues = PendingMeshMaterialQueues::PendingMeshMaterialQueues()
  ignore(pending_queues.prepare_for_new_frame(retained_view))
  world.insert_resource(PendingMeshMaterialQueues::resource(), pending_queues)
  let material_instances = RenderMaterialInstances::RenderMaterialInstances()
  material_instances.extract_mesh_material(
    missing_mesh.id(),
    true,
    MeshMaterial3d::new(@asset.Handle::new(560)),
  )
  material_instances.extract_mesh_material(
    ready.id(),
    true,
    MeshMaterial3d::new(@asset.Handle::new(570)),
  )
  world.insert_resource(ecs_key_render_material_instances, material_instances)
  let mesh_instances = RenderMeshInstances::new()
  let ready_flags = RenderMeshInstanceFlags::has_previous_skin().or(
    RenderMeshInstanceFlags::has_previous_morph(),
  )
  mesh_instances.insert(
    ready,
    RenderMeshQueueData::new(570, 0U, true, flags=ready_flags),
  )
  world.insert_resource(RenderMeshInstances::resource(), mesh_instances)

  let missing_material_ready = render3d_material_specialization_queue_data(
    world, retained_view, render_entity, missing_material,
  )
  let missing_mesh_ready = render3d_material_specialization_queue_data(
    world, retained_view, render_entity, missing_mesh,
  )
  let ready_value = render3d_material_specialization_queue_data(
    world, retained_view, render_entity, ready,
  ).unwrap()

  debug_inspect(missing_material_ready is None, content="true")
  debug_inspect(missing_mesh_ready is None, content="true")
  debug_inspect(
    ready_value.flags().contains(RenderMeshInstanceFlags::has_previous_skin()),
    content="true",
  )
  debug_inspect(
    ready_value.flags().contains(RenderMeshInstanceFlags::has_previous_morph()),
    content="true",
  )
  match world.get_resource(PendingMeshMaterialQueues::resource()) {
    Some(queues) =>
      debug_inspect(queues.current_len(retained_view), content="2")
    None => debug_inspect(false, content="true")
  }
}

///|
struct ShadowReadinessNoShadowMaterial {}

///|
fn ShadowReadinessNoShadowMaterial::ShadowReadinessNoShadowMaterial() -> ShadowReadinessNoShadowMaterial {
  ShadowReadinessNoShadowMaterial::{  }
}

///|
impl @asset.Asset for ShadowReadinessNoShadowMaterial with fn asset_debug_name() {
  "mgstudio_pbr_test::ShadowReadinessNoShadowMaterial"
}

///|
impl @asset.Asset for ShadowReadinessNoShadowMaterial with fn asset_as_image(
  _self,
) {
  None
}

///|
let shadow_readiness_no_shadow_material_asset_keys : @asset.AssetResourceKeys[
  ShadowReadinessNoShadowMaterial,
] = @asset.register_asset_resource_keys(
  ShadowReadinessNoShadowMaterial::asset_debug_name(),
)

///|
impl @asset.Asset for ShadowReadinessNoShadowMaterial with fn asset_resource_keys() {
  shadow_readiness_no_shadow_material_asset_keys
}

///|
let shadow_readiness_no_shadow_material_keys : MaterialKeys[
  ShadowReadinessNoShadowMaterial,
] = register_material_keys(ShadowReadinessNoShadowMaterial::asset_debug_name())

///|
impl Material for ShadowReadinessNoShadowMaterial with fn material_debug_name() {
  "mgstudio_pbr_test::ShadowReadinessNoShadowMaterial"
}

///|
impl Material for ShadowReadinessNoShadowMaterial with fn material_keys() {
  shadow_readiness_no_shadow_material_keys
}

///|
impl Material for ShadowReadinessNoShadowMaterial with fn vertex_shader() {
  material_default_vertex_shader()
}

///|
impl Material for ShadowReadinessNoShadowMaterial with fn fragment_shader() {
  material_default_fragment_shader()
}

///|
impl Material for ShadowReadinessNoShadowMaterial with fn prepass_vertex_shader() {
  material_default_vertex_shader()
}

///|
impl Material for ShadowReadinessNoShadowMaterial with fn prepass_fragment_shader() {
  material_default_fragment_shader()
}

///|
impl Material for ShadowReadinessNoShadowMaterial with fn deferred_vertex_shader() {
  material_default_vertex_shader()
}

///|
impl Material for ShadowReadinessNoShadowMaterial with fn deferred_fragment_shader() {
  material_default_fragment_shader()
}

///|
impl Material for ShadowReadinessNoShadowMaterial with fn meshlet_fragment_shader() {
  material_default_fragment_shader()
}

///|
impl Material for ShadowReadinessNoShadowMaterial with fn meshlet_prepass_fragment_shader() {
  material_default_fragment_shader()
}

///|
impl Material for ShadowReadinessNoShadowMaterial with fn meshlet_deferred_fragment_shader() {
  material_default_fragment_shader()
}

///|
impl Material for ShadowReadinessNoShadowMaterial with fn alpha_mode(self) {
  ignore(self)
  material_default_alpha_mode()
}

///|
impl Material for ShadowReadinessNoShadowMaterial with fn opaque_render_method(
  self,
) {
  ignore(self)
  material_default_opaque_render_method()
}

///|
impl Material for ShadowReadinessNoShadowMaterial with fn depth_bias(self) {
  ignore(self)
  material_default_depth_bias()
}

///|
impl Material for ShadowReadinessNoShadowMaterial with fn reads_view_transmission_texture(
  self,
) {
  ignore(self)
  material_default_reads_view_transmission_texture()
}

///|
impl Material for ShadowReadinessNoShadowMaterial with fn enable_prepass() {
  material_default_enable_prepass()
}

///|
impl Material for ShadowReadinessNoShadowMaterial with fn enable_shadows() {
  false
}

///|
impl Material for ShadowReadinessNoShadowMaterial with fn bindless_supported(
  render_device,
) {
  material_default_bindless_supported(render_device)
}

///|
impl Material for ShadowReadinessNoShadowMaterial with fn bindless_slot_count() {
  material_default_bindless_slot_count()
}

///|
impl Material for ShadowReadinessNoShadowMaterial with fn bind_group(self) {
  ignore(self)
  MaterialBindGroup::MaterialBindGroup()
}

///|
impl Material for ShadowReadinessNoShadowMaterial with fn specialize(
  descriptor,
  layout,
  key,
) {
  material_default_specialize(descriptor, layout, key)
}

///|
test "render3d: shadow specialization readiness follows Bevy pending queue rules" {
  let plugin : MaterialPlugin[ParityCustomMaterial] = MaterialPlugin::MaterialPlugin().with_asset_init(fn() {
      ParityCustomMaterial::ParityCustomMaterial()
    },
  )
  let no_shadow_plugin : MaterialPlugin[ShadowReadinessNoShadowMaterial] = MaterialPlugin::MaterialPlugin().with_asset_init(fn() {
      ShadowReadinessNoShadowMaterial::ShadowReadinessNoShadowMaterial()
    },
  )
  let app = @app.App::new(@ecs.World::new())
    .add_plugins(@render.RenderPlugin::RenderPlugin())
    .add_plugins(plugin)
    .add_plugins(no_shadow_plugin)
  let world = app.sub_app(@app.RenderApp).world()
  let retained_view = @render_view.RetainedViewEntity::new(
    @core.Entity::new(58, 1),
  )
  let render_entity = @core.Entity::new(59, 1)
  let missing_material = @render.MainEntity::new(world.spawn_empty())
  let missing_mesh = @render.MainEntity::new(world.spawn_empty())
  let missing_prepared = @render.MainEntity::new(world.spawn_empty())
  let no_shadows = @render.MainEntity::new(world.spawn_empty())
  let missing_render_mesh = @render.MainEntity::new(world.spawn_empty())
  let ready = @render.MainEntity::new(world.spawn_empty())
  let non_shadow_caster = @render.MainEntity::new(world.spawn_empty())
  let shadow_queues = @pbr_render.PendingShadowQueues::PendingShadowQueues()
  ignore(shadow_queues.queues().prepare_for_new_frame(retained_view))
  world.insert_resource(
    @pbr_render.PendingShadowQueues::resource(),
    shadow_queues,
  )
  let material_key : @ecs.ComponentKey[
    MeshMaterial3dTyped[ParityCustomMaterial],
  ] = MeshMaterial3dTyped::component()
  let no_shadow_material_key : @ecs.ComponentKey[
    MeshMaterial3dTyped[ShadowReadinessNoShadowMaterial],
  ] = MeshMaterial3dTyped::component()
  let prepared_assets_key : @ecs.ResourceKey[
    @render.RenderAssets[PreparedMaterial[ParityCustomMaterial]],
  ] = @render.RenderAssets::resource()
  let no_shadow_prepared_assets_key : @ecs.ResourceKey[
    @render.RenderAssets[PreparedMaterial[ShadowReadinessNoShadowMaterial]],
  ] = @render.RenderAssets::resource()
  let probe : @asset.Handle[ParityCustomMaterial] = @asset.Handle::new(0)
  let pipeline = material_pipeline_from_material_hooks(probe)
  let no_shadow_probe : @asset.Handle[ShadowReadinessNoShadowMaterial] = @asset.Handle::new(
    0,
  )
  let no_shadow_pipeline = material_pipeline_from_material_hooks(
    no_shadow_probe,
  )
  let prepared_assets = match world.get_resource_mut(prepared_assets_key) {
    Some(value) => value
    None => abort("missing PreparedMaterial render assets")
  }
  let no_shadow_prepared_assets = match
    world.get_resource_mut(no_shadow_prepared_assets_key) {
    Some(value) => value
    None => abort("missing no-shadow PreparedMaterial render assets")
  }
  let material_instances = RenderMaterialInstances::RenderMaterialInstances()
  material_instances.extract_mesh_material(
    missing_mesh.id(),
    true,
    MeshMaterial3d::new(@asset.Handle::new(610)),
  )
  material_instances.extract_mesh_material(
    missing_prepared.id(),
    true,
    MeshMaterial3d::new(@asset.Handle::new(620)),
  )
  material_instances.extract_mesh_material(
    no_shadows.id(),
    true,
    MeshMaterial3d::new(@asset.Handle::new(630)),
  )
  material_instances.extract_mesh_material(
    missing_render_mesh.id(),
    true,
    MeshMaterial3d::new(@asset.Handle::new(635)),
  )
  material_instances.extract_mesh_material(
    ready.id(),
    true,
    MeshMaterial3d::new(@asset.Handle::new(640)),
  )
  material_instances.extract_mesh_material(
    non_shadow_caster.id(),
    true,
    MeshMaterial3d::new(@asset.Handle::new(650)),
  )
  world.insert_resource(ecs_key_render_material_instances, material_instances)
  try! world.set_by_key(
    missing_prepared.id(),
    material_key,
    MeshMaterial3dTyped::new(@asset.Handle::new(620)),
  )
  try! world.set_by_key(
    no_shadows.id(),
    no_shadow_material_key,
    MeshMaterial3dTyped::new(@asset.Handle::new(630)),
  )
  try! world.set_by_key(
    ready.id(),
    material_key,
    MeshMaterial3dTyped::new(@asset.Handle::new(640)),
  )
  try! world.set_by_key(
    missing_render_mesh.id(),
    material_key,
    MeshMaterial3dTyped::new(@asset.Handle::new(635)),
  )
  try! world.set_by_key(
    non_shadow_caster.id(),
    material_key,
    MeshMaterial3dTyped::new(@asset.Handle::new(650)),
  )
  prepared_assets.modify(fn(value) {
    value.insert(
      635,
      PreparedMaterial::from_material(
        @asset.Handle::new(635),
        ParityCustomMaterial::ParityCustomMaterial(),
        pipeline,
      ),
    )
    value.insert(
      640,
      PreparedMaterial::from_material(
        @asset.Handle::new(640),
        ParityCustomMaterial::ParityCustomMaterial(),
        pipeline,
      ),
    )
    value.insert(
      650,
      PreparedMaterial::from_material(
        @asset.Handle::new(650),
        ParityCustomMaterial::ParityCustomMaterial(),
        pipeline,
      ),
    )
  })
  no_shadow_prepared_assets.modify(fn(value) {
    value.insert(
      630,
      PreparedMaterial::from_material(
        @asset.Handle::new(630),
        ShadowReadinessNoShadowMaterial::ShadowReadinessNoShadowMaterial(),
        no_shadow_pipeline,
      ),
    )
  })
  let mesh_instances = RenderMeshInstances::new()
  let ready_flags = RenderMeshInstanceFlags::shadow_caster()
  mesh_instances.insert(
    missing_prepared,
    RenderMeshQueueData::new(620, 0U, true, flags=ready_flags),
  )
  mesh_instances.insert(
    no_shadows,
    RenderMeshQueueData::new(630, 0U, true, flags=ready_flags),
  )
  mesh_instances.insert(
    missing_render_mesh,
    RenderMeshQueueData::new(635, 0U, true, flags=ready_flags),
  )
  mesh_instances.insert(
    ready,
    RenderMeshQueueData::new(640, 0U, true, flags=ready_flags),
  )
  mesh_instances.insert(
    non_shadow_caster,
    RenderMeshQueueData::new(650, 0U, true),
  )
  world.insert_resource(RenderMeshInstances::resource(), mesh_instances)
  let render_mesh_assets = @render_mesh.RenderMeshAssets::RenderMeshAssets()
  render_mesh_assets.insert(
    640,
    @render_mesh.RenderMesh::new(
      vertex_count=3,
      key_bits=@mesh.BaseMeshPipelineKey::new(32UL),
    ),
  )
  world.insert_resource(
    @render_mesh.RenderMeshAssets::resource(),
    render_mesh_assets,
  )

  let missing_material_ready = render3d_shadow_specialization_queue_data(
    world, retained_view, render_entity, missing_material,
  )
  let missing_mesh_ready = render3d_shadow_specialization_queue_data(
    world, retained_view, render_entity, missing_mesh,
  )
  let missing_prepared_ready = render3d_shadow_specialization_queue_data(
    world, retained_view, render_entity, missing_prepared,
  )
  let no_shadows_ready = render3d_shadow_specialization_queue_data(
    world, retained_view, render_entity, no_shadows,
  )
  let missing_render_mesh_ready = render3d_shadow_specialization_queue_data(
    world, retained_view, render_entity, missing_render_mesh,
  )
  let ready_value = render3d_shadow_specialization_queue_data(
    world, retained_view, render_entity, ready,
  ).unwrap()
  let ready_work_item = render3d_shadow_specialization_work_item_data(
    world,
    retained_view,
    render_entity,
    ready,
    @material.ErasedMeshPipelineKey::new(8UL, "MeshPipelineKey"),
  ).unwrap()
  let non_shadow_caster_ready = render3d_shadow_specialization_queue_data(
    world, retained_view, render_entity, non_shadow_caster,
  )

  debug_inspect(missing_material_ready is None, content="true")
  debug_inspect(missing_mesh_ready is None, content="true")
  debug_inspect(missing_prepared_ready is None, content="true")
  debug_inspect(no_shadows_ready is None, content="true")
  debug_inspect(missing_render_mesh_ready is None, content="true")
  debug_inspect(
    ready_value.flags().contains(RenderMeshInstanceFlags::shadow_caster()),
    content="true",
  )
  inspect(ready_work_item.mesh_key().bits(), content="40")
  debug_inspect(ready_work_item.properties().shadows_enabled, content="true")
  debug_inspect(non_shadow_caster_ready is None, content="true")
  match world.get_resource(@pbr_render.PendingShadowQueues::resource()) {
    Some(queues) =>
      debug_inspect(queues.queues().current_len(retained_view), content="3")
    None => debug_inspect(false, content="true")
  }
}

///|
test "render3d: shadow specialization mesh key mirrors Bevy work item assembly" {
  let visible_entity = @render.MainEntity::new(@core.Entity::new(71, 1))
  let light_key = @material.ErasedMeshPipelineKey::new(8UL, "MeshPipelineKey")
  let render_mesh = @render_mesh.RenderMesh::new(
    vertex_count=3,
    key_bits=@mesh.BaseMeshPipelineKey::new(32UL),
  )
  let opaque_properties = @material.MaterialProperties::MaterialProperties()
  let opaque_key = render3d_shadow_specialization_mesh_key(
    light_key,
    render_mesh,
    opaque_properties,
    None,
    visible_entity,
  )
  inspect(opaque_key.bits(), content="40")

  let render_lightmaps = @lightmap.RenderLightmaps::RenderLightmaps()
  ignore(
    render_lightmaps.insert_lightmap(
      visible_entity.id(),
      @lightmap.Lightmap::new(@asset.Handle::new(5)),
    ),
  )
  let blend_properties = @material.MaterialProperties::MaterialProperties().with_alpha_mode(
    @material.AlphaMode3d::Blend,
  )
  let blend_lightmapped_key = render3d_shadow_specialization_mesh_key(
    light_key,
    render_mesh,
    blend_properties,
    Some(render_lightmaps),
    visible_entity,
  )
  inspect(blend_lightmapped_key.bits(), content="4200")

  let multiply_properties = @material.MaterialProperties::MaterialProperties().with_alpha_mode(
    @material.AlphaMode3d::Multiply,
  )
  let multiply_key = render3d_shadow_specialization_mesh_key(
    light_key,
    render_mesh,
    multiply_properties,
    None,
    visible_entity,
  )
  inspect(multiply_key.bits() & MESH_PIPELINE_KEY_MAY_DISCARD, content="0")
}

///|
test "render3d: shadow specialization work item selects Bevy draw function" {
  let world = @ecs.World::new()
  let retained_view = @render_view.RetainedViewEntity::new(
    @core.Entity::new(73, 1),
  )
  let visible_entity = @render.MainEntity::new(@core.Entity::new(74, 1))
  world.insert_resource(
    @pbr_render.SpecializedShadowMaterialPipelineCache::resource(),
    @pbr_render.SpecializedShadowMaterialPipelineCache::SpecializedShadowMaterialPipelineCache(),
  )
  let properties = @material.MaterialProperties::MaterialProperties()
    .with_prepass_specialize(Some(material_test_base_specialize))
    .with_material_key(@material.ErasedMaterialKey::new(19UL, "MaterialKey"))
    .add_draw_function(
      SHADOWS_DRAW_FUNCTION_LABEL,
      @material.DrawFunctionId::new(11U),
    )
    .add_draw_function(
      SHADOWS_DEPTH_ONLY_DRAW_FUNCTION_LABEL,
      @material.DrawFunctionId::new(12U),
    )
  let item = Render3dShadowSpecializationWorkItemData::{
    queue_data: RenderMeshQueueData::new(80, 0U, false),
    visible_entity,
    retained_view_entity: retained_view,
    mesh_key: @material.ErasedMeshPipelineKey::new(4UL, "MeshPipelineKey"),
    layout: @render_mesh.RenderMesh::new(vertex_count=3).layout(),
    properties,
    material_type_tag: "TestMaterial",
  }
  let specialized = render3d_shadow_specialization_apply_work_item(
    world, item, false,
  )
  guard world.get_resource(
      @pbr_render.SpecializedShadowMaterialPipelineCache::resource(),
    )
    is Some(cache) else {
    abort("missing shadow cache")
  }
  guard cache.get(retained_view) is Some(view_cache) else {
    abort("missing retained view shadow cache")
  }
  guard view_cache.get(visible_entity) is Some(entry) else {
    abort("missing visible entity shadow cache")
  }
  let (pipeline_id, draw_function) = entry
  debug_inspect(specialized, content="true")
  inspect(pipeline_id.id(), content="901")
  inspect(draw_function.id(), content="12")
}

///|
test "render3d: shadow specialization uses material draw when prepass reads material" {
  let world = @ecs.World::new()
  let retained_view = @render_view.RetainedViewEntity::new(
    @core.Entity::new(75, 1),
  )
  let visible_entity = @render.MainEntity::new(@core.Entity::new(76, 1))
  world.insert_resource(
    @pbr_render.SpecializedShadowMaterialPipelineCache::resource(),
    @pbr_render.SpecializedShadowMaterialPipelineCache::SpecializedShadowMaterialPipelineCache(),
  )
  let properties = @material.MaterialProperties::MaterialProperties()
    .with_prepass_specialize(Some(material_test_base_specialize))
    .with_material_key(@material.ErasedMaterialKey::new(23UL, "MaterialKey"))
    .add_draw_function(
      SHADOWS_DRAW_FUNCTION_LABEL,
      @material.DrawFunctionId::new(21U),
    )
    .add_draw_function(
      SHADOWS_DEPTH_ONLY_DRAW_FUNCTION_LABEL,
      @material.DrawFunctionId::new(22U),
    )
  let item = Render3dShadowSpecializationWorkItemData::{
    queue_data: RenderMeshQueueData::new(81, 0U, false),
    visible_entity,
    retained_view_entity: retained_view,
    mesh_key: @material.ErasedMeshPipelineKey::new(
      4UL | MESH_PIPELINE_KEY_PREPASS_READS_MATERIAL,
      "MeshPipelineKey",
    ),
    layout: @render_mesh.RenderMesh::new(vertex_count=3).layout(),
    properties,
    material_type_tag: "TestMaterial",
  }
  let specialized = render3d_shadow_specialization_apply_work_item(
    world, item, true,
  )
  guard world.get_resource(
      @pbr_render.SpecializedShadowMaterialPipelineCache::resource(),
    )
    is Some(cache) else {
    abort("missing shadow cache")
  }
  guard cache.get(retained_view) is Some(view_cache) else {
    abort("missing retained view shadow cache")
  }
  guard view_cache.get(visible_entity) is Some(entry) else {
    abort("missing visible entity shadow cache")
  }
  let (pipeline_id, draw_function) = entry
  debug_inspect(specialized, content="true")
  inspect(pipeline_id.id(), content="901")
  inspect(draw_function.id(), content="21")
}

///|
test "render3d: shadow specialization drains work items and expires stale views" {
  let world = @ecs.World::new()
  let live_view = @render_view.RetainedViewEntity::new(@core.Entity::new(77, 1))
  let stale_view = @render_view.RetainedViewEntity::new(
    @core.Entity::new(78, 1),
  )
  let live_entity = @render.MainEntity::new(@core.Entity::new(79, 1))
  let stale_entity = @render.MainEntity::new(@core.Entity::new(80, 1))
  let cache = @pbr_render.SpecializedShadowMaterialPipelineCache::SpecializedShadowMaterialPipelineCache()
  cache.insert(
    stale_view,
    stale_entity,
    @material.CachedRenderPipelineId::new(700UL),
    @material.DrawFunctionId::new(70U),
  )
  world.insert_resource(
    @pbr_render.SpecializedShadowMaterialPipelineCache::resource(),
    cache,
  )
  let properties = @material.MaterialProperties::MaterialProperties()
    .with_prepass_specialize(Some(material_test_base_specialize))
    .with_material_key(@material.ErasedMaterialKey::new(29UL, "MaterialKey"))
    .add_draw_function(
      SHADOWS_DRAW_FUNCTION_LABEL,
      @material.DrawFunctionId::new(31U),
    )
    .add_draw_function(
      SHADOWS_DEPTH_ONLY_DRAW_FUNCTION_LABEL,
      @material.DrawFunctionId::new(32U),
    )
  let skipped_properties = @material.MaterialProperties::MaterialProperties()
    .with_material_key(@material.ErasedMaterialKey::new(30UL, "MaterialKey"))
    .add_draw_function(
      SHADOWS_DEPTH_ONLY_DRAW_FUNCTION_LABEL,
      @material.DrawFunctionId::new(33U),
    )
  let work_items = [
    Render3dShadowSpecializationWorkItemData::{
      queue_data: RenderMeshQueueData::new(82, 0U, false),
      visible_entity: live_entity,
      retained_view_entity: live_view,
      mesh_key: @material.ErasedMeshPipelineKey::new(4UL, "MeshPipelineKey"),
      layout: @render_mesh.RenderMesh::new(vertex_count=3).layout(),
      properties,
      material_type_tag: "TestMaterial",
    },
    Render3dShadowSpecializationWorkItemData::{
      queue_data: RenderMeshQueueData::new(83, 0U, false),
      visible_entity: stale_entity,
      retained_view_entity: live_view,
      mesh_key: @material.ErasedMeshPipelineKey::new(4UL, "MeshPipelineKey"),
      layout: @render_mesh.RenderMesh::new(vertex_count=3).layout(),
      properties: skipped_properties,
      material_type_tag: "TestMaterial",
    },
  ]
  let live_views : @hashset.HashSet[@render_view.RetainedViewEntity] = @hashset.HashSet([],
  )
  live_views.add(live_view)
  let count = render3d_shadow_specialization_apply_work_items(
    world, work_items, live_views, false,
  )

  guard world.get_resource(
      @pbr_render.SpecializedShadowMaterialPipelineCache::resource(),
    )
    is Some(updated_cache) else {
    abort("missing shadow cache")
  }
  debug_inspect(count, content="1")
  debug_inspect(work_items.length(), content="0")
  debug_inspect(updated_cache.get(stale_view) is None, content="true")
  guard updated_cache.get(live_view) is Some(view_cache) else {
    abort("missing live shadow cache")
  }
  guard view_cache.get(live_entity) is Some(entry) else {
    abort("missing live shadow cache entry")
  }
  let (pipeline_id, draw_function) = entry
  inspect(pipeline_id.id(), content="901")
  inspect(draw_function.id(), content="32")
  debug_inspect(view_cache.get(stale_entity) is None, content="true")
}

///|
test "render3d: queue shadows mirrors Bevy cache layers bindings and pending rules" {
  let plugin : MaterialPlugin[ParityCustomMaterial] = MaterialPlugin::MaterialPlugin().with_asset_init(fn() {
      ParityCustomMaterial::ParityCustomMaterial()
    },
  )
  let app = @app.App::new(@ecs.World::new())
    .add_plugins(@render.RenderPlugin::RenderPlugin())
    .add_plugins(plugin)
  let world = app.sub_app(@app.RenderApp).world()
  let retained_view = @render_view.RetainedViewEntity::new(
    @core.Entity::new(90, 1),
  )
  let depth_render = @core.Entity::new(91, 1)
  let material_render = @core.Entity::new(92, 1)
  let layer_render = @core.Entity::new(93, 1)
  let missing_mesh_render = @core.Entity::new(94, 1)
  let missing_binding_render = @core.Entity::new(95, 1)
  let cache_miss_render = @core.Entity::new(96, 1)
  let depth_main = @render.MainEntity::new(world.spawn_empty())
  let material_main = @render.MainEntity::new(world.spawn_empty())
  let layer_main = @render.MainEntity::new(world.spawn_empty())
  let missing_mesh_main = @render.MainEntity::new(world.spawn_empty())
  let missing_binding_main = @render.MainEntity::new(world.spawn_empty())
  let cache_miss_main = @render.MainEntity::new(world.spawn_empty())
  let visible_entities = @render_visibility.RenderVisibleEntities::RenderVisibleEntities()
  let visible_meshes = visible_entities.class_or_insert(
    render3d_mesh_visibility_class(),
  )
  visible_meshes.prepare_for_new_frame()
  visible_meshes.update_cpu_culled_entities([
    (depth_render, depth_main),
    (material_render, material_main),
    (layer_render, layer_main),
    (missing_mesh_render, missing_mesh_main),
    (missing_binding_render, missing_binding_main),
    (cache_miss_render, cache_miss_main),
  ])
  visible_meshes.sort_added_entities()
  let dirty_specializations = @render_visibility.DirtySpecializations::DirtySpecializations()
  dirty_specializations.insert_view(retained_view)
  let pending_shadow_queues = @pbr_render.PendingShadowQueues::PendingShadowQueues()
  ignore(pending_shadow_queues.queues().prepare_for_new_frame(retained_view))
  world.insert_resource(
    @pbr_render.PendingShadowQueues::resource(),
    pending_shadow_queues,
  )
  let material_key : @ecs.ComponentKey[
    MeshMaterial3dTyped[ParityCustomMaterial],
  ] = MeshMaterial3dTyped::component()
  let prepared_assets_key : @ecs.ResourceKey[
    @render.RenderAssets[PreparedMaterial[ParityCustomMaterial]],
  ] = @render.RenderAssets::resource()
  let draw_function_ids = pbr_material_register_draw_functions(
    @material.DrawFunctions::DrawFunctions(),
  )
  let probe : @asset.Handle[ParityCustomMaterial] = @asset.Handle::new(0)
  let pipeline = material_pipeline_from_material_hooks(probe)
  let prepared_depth_base = PreparedMaterial::from_material(
    @asset.Handle::new(701),
    ParityCustomMaterial::ParityCustomMaterial(),
    pipeline,
  )
  let prepared_depth = PreparedMaterial::{
    ..prepared_depth_base,
    properties: pbr_material_apply_draw_functions(
      prepared_depth_base.properties(),
      draw_function_ids,
    ),
  }
  let prepared_material_base = PreparedMaterial::from_material(
    @asset.Handle::new(702),
    ParityCustomMaterial::ParityCustomMaterial(),
    pipeline,
  )
  let prepared_material = PreparedMaterial::{
    ..prepared_material_base,
    properties: pbr_material_apply_draw_functions(
      prepared_material_base.properties(),
      draw_function_ids,
    ),
  }
  let prepared_layer_base = PreparedMaterial::from_material(
    @asset.Handle::new(703),
    ParityCustomMaterial::ParityCustomMaterial(),
    pipeline,
  )
  let prepared_layer = PreparedMaterial::{
    ..prepared_layer_base,
    properties: pbr_material_apply_draw_functions(
      prepared_layer_base.properties(),
      draw_function_ids,
    ),
  }
  let prepared_missing_binding_base = PreparedMaterial::from_material(
    @asset.Handle::new(704),
    ParityCustomMaterial::ParityCustomMaterial(),
    pipeline,
  )
  let prepared_missing_binding = PreparedMaterial::{
    ..prepared_missing_binding_base,
    properties: pbr_material_apply_draw_functions(
      prepared_missing_binding_base.properties(),
      draw_function_ids,
    ),
  }
  let prepared_cache_miss_base = PreparedMaterial::from_material(
    @asset.Handle::new(705),
    ParityCustomMaterial::ParityCustomMaterial(),
    pipeline,
  )
  let prepared_cache_miss = PreparedMaterial::{
    ..prepared_cache_miss_base,
    properties: pbr_material_apply_draw_functions(
      prepared_cache_miss_base.properties(),
      draw_function_ids,
    ),
  }
  let depth_draw = prepared_depth
    .properties()
    .get_draw_function(SHADOWS_DEPTH_ONLY_DRAW_FUNCTION_LABEL)
    .unwrap()
  let material_draw = prepared_material
    .properties()
    .get_draw_function(SHADOWS_DRAW_FUNCTION_LABEL)
    .unwrap()
  let prepared_assets = match world.get_resource_mut(prepared_assets_key) {
    Some(value) => value
    None => abort("missing PreparedMaterial render assets")
  }
  prepared_assets.modify(fn(value) {
    value.insert(701, prepared_depth)
    value.insert(702, prepared_material)
    value.insert(703, prepared_layer)
    value.insert(704, prepared_missing_binding)
    value.insert(705, prepared_cache_miss)
  })
  let material_instances = RenderMaterialInstances::RenderMaterialInstances()
  material_instances.extract_mesh_material(
    depth_main.id(),
    true,
    MeshMaterial3d::new(@asset.Handle::new(701)),
  )
  material_instances.extract_mesh_material(
    material_main.id(),
    true,
    MeshMaterial3d::new(@asset.Handle::new(702)),
  )
  material_instances.extract_mesh_material(
    layer_main.id(),
    true,
    MeshMaterial3d::new(@asset.Handle::new(703)),
  )
  material_instances.extract_mesh_material(
    missing_binding_main.id(),
    true,
    MeshMaterial3d::new(@asset.Handle::new(704)),
  )
  material_instances.extract_mesh_material(
    cache_miss_main.id(),
    true,
    MeshMaterial3d::new(@asset.Handle::new(705)),
  )
  world.insert_resource(ecs_key_render_material_instances, material_instances)
  for
    entry in [
      (depth_main, 701),
      (material_main, 702),
      (layer_main, 703),
      (missing_binding_main, 704),
      (cache_miss_main, 705),
    ] {
    let (main_entity, material_id) = entry
    try! world.set_by_key(
      main_entity.id(),
      material_key,
      MeshMaterial3dTyped::new(@asset.Handle::new(material_id)),
    )
  }
  let shadow_cache = @pbr_render.SpecializedShadowMaterialPipelineCache::SpecializedShadowMaterialPipelineCache()
  shadow_cache.insert(
    retained_view,
    depth_main,
    @material.CachedRenderPipelineId::new(801UL),
    depth_draw,
  )
  shadow_cache.insert(
    retained_view,
    material_main,
    @material.CachedRenderPipelineId::new(802UL),
    material_draw,
  )
  shadow_cache.insert(
    retained_view,
    layer_main,
    @material.CachedRenderPipelineId::new(803UL),
    depth_draw,
  )
  shadow_cache.insert(
    retained_view,
    missing_mesh_main,
    @material.CachedRenderPipelineId::new(804UL),
    depth_draw,
  )
  shadow_cache.insert(
    retained_view,
    missing_binding_main,
    @material.CachedRenderPipelineId::new(805UL),
    material_draw,
  )
  world.insert_resource(
    @pbr_render.SpecializedShadowMaterialPipelineCache::resource(),
    shadow_cache,
  )
  let mesh_instances = RenderMeshInstances::new(
    use_gpu_instance_buffer_builder=true,
  )
  let shadow_flags = RenderMeshInstanceFlags::shadow_caster()
  let visible_layer = @camera_render_layers.RenderLayers::layer(1)
  mesh_instances.insert(
    depth_main,
    RenderMeshQueueData::new(
      701,
      11U,
      true,
      flags=shadow_flags,
      render_layers=Some(visible_layer),
    ),
  )
  mesh_instances.insert(
    material_main,
    RenderMeshQueueData::new(
      702,
      12U,
      true,
      flags=shadow_flags,
      render_layers=Some(visible_layer),
    ),
  )
  mesh_instances.insert(
    layer_main,
    RenderMeshQueueData::new(
      703,
      13U,
      true,
      flags=shadow_flags,
      render_layers=Some(@camera_render_layers.RenderLayers::layer(2)),
    ),
  )
  mesh_instances.insert(
    missing_binding_main,
    RenderMeshQueueData::new(
      704,
      14U,
      true,
      flags=shadow_flags,
      render_layers=Some(visible_layer),
    ),
  )
  world.insert_resource(RenderMeshInstances::resource(), mesh_instances)
  let material_bindings = RenderMaterialBindings::RenderMaterialBindings()
  material_bindings.set(
    702,
    MaterialBindingId::new(
      MaterialBindGroupIndex::new(7),
      MaterialBindGroupSlot::new(3),
    ),
  )
  world.insert_resource(RenderMaterialBindings::resource(), material_bindings)
  let mesh_allocator = @render_mesh.MeshAllocator::new()
  for mesh_id in [701, 702, 703, 704, 705] {
    ignore(
      mesh_allocator.allocate(
        mesh_id,
        96,
        @render_mesh.MeshAllocatorElementLayout::vertex(32),
      ),
    )
  }
  world.insert_resource(@render_mesh.MeshAllocator::resource(), mesh_allocator)

  let queued = render3d_queue_shadow_phase_data_for_visible_entities(
    world,
    retained_view,
    visible_entities,
    Some(@camera_render_layers.RenderLayers::layer(1)),
    dirty_specializations,
    pending_shadow_queues,
  )

  debug_inspect(queued.dequeued().length(), content="6")
  debug_inspect(queued.items().length(), content="2")
  let first = queued.items()[0]
  let second = queued.items()[1]
  inspect(first.pipeline_id().id(), content="801")
  debug_inspect(first.material_bind_group_index(), content="None")
  inspect(first.current_uniform_index().reinterpret_as_int(), content="11")
  let first_batch_key = first.batch_set_key()
  let first_bin_key = first.bin_key()
  inspect(first_batch_key.pipeline_id().id(), content="801")
  inspect(first_batch_key.draw_function().id(), content="10")
  debug_inspect(first_batch_key.material_bind_group_index(), content="None")
  debug_inspect(first_batch_key.indexed(), content="false")
  inspect(first_bin_key.mesh_asset_id(), content="701")
  inspect(second.pipeline_id().id(), content="802")
  debug_inspect(second.material_bind_group_index(), content="Some(7)")
  inspect(second.current_uniform_index().reinterpret_as_int(), content="12")
  let second_batch_key = second.batch_set_key()
  let second_bin_key = second.bin_key()
  inspect(second_batch_key.pipeline_id().id(), content="802")
  inspect(second_batch_key.draw_function().id(), content="9")
  debug_inspect(second_batch_key.material_bind_group_index(), content="Some(7)")
  debug_inspect(second_batch_key.indexed(), content="false")
  inspect(second_bin_key.mesh_asset_id(), content="702")
  let shadow_phase = Render3dShadowViewPhaseData::new(
    @render_batching.GpuPreprocessingMode::None,
  )
  shadow_phase.add(
    Render3dShadowBatchSetKeyData::new(
      @material.CachedRenderPipelineId::new(999UL),
      depth_draw,
      None,
      first.slabs(),
    ),
    Render3dShadowBinKeyData::new(705),
    (cache_miss_render, cache_miss_main),
    99U,
    Render3dShadowBinnedRenderPhaseType::mesh(
      true,
      @render_batching.GpuPreprocessingSupport::GpuPreprocessingSupport(),
    ),
  )
  shadow_phase.apply_queue(
    queued,
    @render_batching.GpuPreprocessingSupport::GpuPreprocessingSupport(),
  )
  debug_inspect(shadow_phase.len(), content="2")
  debug_inspect(
    shadow_phase.input_uniform_index(depth_main),
    content="Some(11)",
  )
  debug_inspect(
    shadow_phase.input_uniform_index(material_main),
    content="Some(12)",
  )
  debug_inspect(
    shadow_phase.input_uniform_index(cache_miss_main),
    content="None",
  )
  debug_inspect(
    shadow_phase.phase_type(depth_main),
    content="Some(BatchableMesh)",
  )
  let shadow_phase_items = shadow_phase.items()
  inspect(shadow_phase_items[0].cached_pipeline().id(), content="801")
  inspect(shadow_phase_items[0].batch_range().start(), content="11")
  inspect(shadow_phase_items[0].batch_range().end(), content="12")
  inspect(shadow_phase_items[1].cached_pipeline().id(), content="802")
  inspect(shadow_phase_items[1].batch_range().start(), content="12")
  inspect(shadow_phase_items[1].batch_range().end(), content="13")
  match world.get_resource(@pbr_render.PendingShadowQueues::resource()) {
    Some(queues) =>
      debug_inspect(queues.queues().current_len(retained_view), content="2")
    None => debug_inspect(false, content="true")
  }
}

///|
test "render3d: missing prepared render mesh does not return to pending queue" {
  let world = @ecs.World::new()
  let main_view = @core.Entity::new(61, 1)
  let render_view = world.spawn()
  let render_entity = @core.Entity::new(62, 1)
  let visible_entity = @render.MainEntity::new(@core.Entity::new(63, 1))
  let retained_view = @render_view.RetainedViewEntity::new(main_view)
  let visible_entities = @render_visibility.RenderVisibleEntities::RenderVisibleEntities()
  let visible_class = visible_entities.class_or_insert(
    render3d_mesh_visibility_class(),
  )
  visible_class.prepare_for_new_frame()
  visible_class.update_cpu_culled_entities([(render_entity, visible_entity)])
  visible_class.sort_added_entities()
  try! world.set_by_key(
    render_view, @render_visibility.ecs_key_render_visible_entities, visible_entities,
  )
  let dirty_specializations = @render_visibility.DirtySpecializations::DirtySpecializations()
  dirty_specializations.insert_changed(visible_entity)
  world.insert_resource(
    @render_visibility.DirtySpecializations::resource(),
    dirty_specializations,
  )
  world.insert_resource(
    PendingMeshMaterialQueues::resource(),
    PendingMeshMaterialQueues::PendingMeshMaterialQueues(),
  )
  world.insert_resource(
    ecs_key_specialized_material_pipeline_cache,
    SpecializedMaterialPipelineCache::SpecializedMaterialPipelineCache(),
  )
  let material_instances = RenderMaterialInstances::RenderMaterialInstances()
  material_instances.extract_mesh_material(
    visible_entity.id(),
    true,
    MeshMaterial3d::new(@asset.Handle::new(630)),
  )
  world.insert_resource(ecs_key_render_material_instances, material_instances)
  let mesh_instances = RenderMeshInstances::new()
  mesh_instances.insert(visible_entity, RenderMeshQueueData::new(630, 0U, true))
  world.insert_resource(RenderMeshInstances::resource(), mesh_instances)
  let camera = ExtractedCamera3d::{
    entity: phase_entity_ref3d(main_view, render_view),
    payload: material_test_camera_payload(),
  }

  render3d_prewarm_mesh_pipelines(
    world,
    @pbr_render.Render3dMeshRuntimeState::new(),
    [camera],
    [],
  )

  match world.get_resource(PendingMeshMaterialQueues::resource()) {
    Some(queues) =>
      debug_inspect(queues.current_len(retained_view), content="0")
    None => debug_inspect(false, content="true")
  }
}

///|
test "render3d: material specialization reads prepared RenderMeshAssets only" {
  let world = @ecs.World::new()
  world.insert_resource(
    ecs_key_specialized_material_pipeline_cache,
    SpecializedMaterialPipelineCache::SpecializedMaterialPipelineCache(),
  )
  let material_properties = @material.MaterialProperties::MaterialProperties().with_base_specialize(
    Some(material_test_base_specialize),
  )
  let extracted_payload_mesh_id = 581
  let render_mesh_asset_id = 580
  let mesh = material_test_extracted_mesh_payload(
    extracted_payload_mesh_id, material_properties,
  )
  let queue_data = RenderMeshQueueData::new(render_mesh_asset_id, 0U, true)
  let retained_view = @render_view.RetainedViewEntity::new(
    @core.Entity::new(58, 1),
  )

  let missing_render_mesh = render3d_prewarm_material_pipeline(
    world,
    @pbr_render.Render3dMeshRuntimeState::new(),
    mesh,
    material_test_camera_payload(),
    retained_view,
    @core.Entity::new(59, 1),
    queue_data,
    1,
  )

  debug_inspect(missing_render_mesh is None, content="true")
  debug_inspect(
    world.get_resource(@render_mesh.RenderMeshAssets::resource()) is None,
    content="true",
  )

  let render_mesh_assets = @render_mesh.RenderMeshAssets::RenderMeshAssets()
  render_mesh_assets.insert(
    render_mesh_asset_id,
    @render_mesh.RenderMesh::new(vertex_count=3),
  )
  world.insert_resource(
    @render_mesh.RenderMeshAssets::resource(),
    render_mesh_assets,
  )
  let prepared_render_mesh = render3d_prewarm_material_pipeline(
    world,
    @pbr_render.Render3dMeshRuntimeState::new(),
    mesh,
    material_test_camera_payload(),
    retained_view,
    @core.Entity::new(59, 1),
    queue_data,
    2,
  )

  debug_inspect(
    prepared_render_mesh.map(fn(value) { value.id() }),
    content="Some(901)",
  )
}

///|
test "render3d: materials startup preserves shadow specialization caches" {
  let world = @ecs.World::new()
  let view = @render_view.RetainedViewEntity::new(
    @core.Entity::new(10, 1),
    auxiliary_entity=Some(@core.Entity::new(20, 1)),
    subview_index=1,
  )
  let main_entity = @render.MainEntity::new(@core.Entity::new(11, 1))
  let light_key_cache = @pbr_render.LightKeyCache::LightKeyCache()
  light_key_cache.insert(
    view,
    @material.ErasedMeshPipelineKey::new(13UL, "MeshPipelineKey"),
  )
  let shadow_cache = @pbr_render.SpecializedShadowMaterialPipelineCache::SpecializedShadowMaterialPipelineCache()
  shadow_cache.insert(
    view,
    main_entity,
    @material.CachedRenderPipelineId::new(21UL),
    @material.DrawFunctionId::new(5U),
  )
  world.insert_resource(@pbr_render.LightKeyCache::resource(), light_key_cache)
  world.insert_resource(
    @pbr_render.SpecializedShadowMaterialPipelineCache::resource(),
    shadow_cache,
  )

  init_materials_resources(world)

  match world.get_resource(@pbr_render.LightKeyCache::resource()) {
    Some(cache) =>
      debug_inspect(
        cache.get(view).map(fn(key) { key.bits() }),
        content="Some(13)",
      )
    None => debug_inspect(false, content="true")
  }
  match
    world.get_resource(
      @pbr_render.SpecializedShadowMaterialPipelineCache::resource(),
    ) {
    Some(cache) =>
      debug_inspect(
        cache.pipeline_id(view, main_entity).map(fn(value) { value.id() }),
        content="Some(21)",
      )
    None => debug_inspect(false, content="true")
  }
}
