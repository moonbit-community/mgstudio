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
fn wireframe_test_main_entity(entity : @core.Entity) -> @render.MainEntity {
  @render.MainEntity::new(entity)
}

///|
fn wireframe_phase_test_descriptor() -> @material.RenderPipelineDescriptor {
  @material.RenderPipelineDescriptor::RenderPipelineDescriptor()
  .with_vertex(
    @material.VertexState::new(Some("base.wgsl"), [], Some("vertex"), [
      @mesh.VertexBufferLayout::new(
        array_stride=12,
        step_mode=@mesh.MeshVertexStepMode::Vertex,
        attributes=[],
      ),
    ]),
  )
  .with_fragment(
    Some(
      @material.FragmentState::new(Some("base.wgsl"), [], Some("fragment"), [
        Some(@material.ColorTargetState::new(1U, 0xffffffffffffffffUL)),
      ]),
    ),
  )
  .with_depth_stencil(Some(@material.DepthStencilState::DepthStencilState()))
}

///|
fn wireframe_phase_test_frame_config() -> Render3dExecuteFrameConfig {
  Render3dExecuteFrameConfig::{
    gpu_instance_buffer_builder_requested: false,
    gpu_culling_supported: false,
    gpu_instance_buffer_builder_enabled: false,
    prepass_enabled: false,
    deferred_lighting_enabled: false,
    delta_seconds: 0.0F,
    default_opaque_renderer_method: OpaqueRendererMethod::Forward,
    point_light_shadow_map_size: 0,
    wireframe_config: None,
  }
}

///|
fn wireframe_phase_test_camera(
  view_entity : @core.Entity,
  motion_vector_prepass_enabled? : Bool = false,
  invert_culling? : Bool = false,
) -> ExtractedCamera3d {
  ExtractedCamera3d::{
    entity: phase_entity_ref3d_for_main(view_entity),
    payload: Camera3dViewPayload::{
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
      motion_vector_prepass_enabled,
      msaa: None,
      transform: @transform.Transform::Transform(),
      previous_transform: @transform.Transform::Transform(),
      previous_clip_from_world: None,
      target_id: 0,
      target_size: @math.IVec2::new(1280, 720),
      scale_factor: 1.0F,
      layers: @camera_render_layers.RenderLayers::RenderLayers(),
      has_no_cpu_culling: false,
      invert_culling,
    },
  }
}

///|
test "pbr: camera view key carries Bevy Camera::invert_culling" {
  let camera = wireframe_phase_test_camera(
    @core.Entity::new(31, 0),
    invert_culling=true,
  )
  let bits = render3d_camera_mesh_pipeline_view_key_bits(camera.payload)
  inspect(bits & MESH_PIPELINE_KEY_INVERT_CULLING, content="4194304")
}

///|
test "pbr: Wireframe3d phase item exposes Bevy phase identity fields" {
  let draw_functions = @material.DrawFunctions::new()
  let draw = draw_functions.register("Wireframe3dThinDrawFunction")
  let batch_set = Wireframe3dBatchSetKey::new(
    @material.CachedRenderPipelineId::new(9UL),
    17,
    draw,
    @render_mesh.MeshSlabs::new(2, index_slab_id=Some(3)),
  )
  let bin = Wireframe3dBinKey::new(31)
  let render_entity = @core.Entity::new(4, 1)
  let main_entity = wireframe_test_main_entity(@core.Entity::new(5, 1))
  let item = Wireframe3d::new(
    batch_set,
    bin,
    render_entity,
    main_entity,
    Wireframe3dBatchRange::new(7, 11),
    WireframePhaseItemExtraIndex::dynamic_offset(64),
  )

  debug_inspect(item.entity() == render_entity, content="true")
  debug_inspect(item.main_entity() == main_entity, content="true")
  debug_inspect(item.draw_function().id(), content="0")
  debug_inspect(item.cached_pipeline().id(), content="9")
  debug_inspect(item.batch_range().count(), content="4")
  debug_inspect(item.extra_index(), content="DynamicOffset(64)")
  debug_inspect(item.batch_set_key().indexed(), content="true")
  debug_inspect(item.bin_key().asset_id(), content="31")
}

///|
test "pbr: Wireframe3d batch set key models wide non-indexed path" {
  let draw_functions = @material.DrawFunctions::new()
  let draw = draw_functions.register("Wireframe3dWideDrawFunction")
  let wide = Wireframe3dBatchSetKey::new(
    @material.CachedRenderPipelineId::new(12UL),
    44,
    draw,
    @render_mesh.MeshSlabs::new(
      5,
      index_slab_id=None,
      morph_target_slab_id=Some(8),
    ),
    mesh_asset_id=Some(99),
  )

  debug_inspect(wide.indexed(), content="false")
  debug_inspect(wide.asset_id(), content="44")
  debug_inspect(wide.mesh_asset_id(), content="Some(99)")
  debug_inspect(wide.slabs().vertex_slab_id(), content="5")
  debug_inspect(wide.slabs().index_slab_id(), content="None")
  debug_inspect(wide.slabs().morph_target_slab_id(), content="Some(8)")
}

///|
test "pbr: WireframePipelineKey follows Bevy wide quads line-mode rules" {
  let mesh_key = @material.ErasedMeshPipelineKey::new(7UL, "MeshPipelineKey")
  let thin = WireframePipelineKey::from_material(
    mesh_key,
    Some(
      RenderWireframeMaterial::from_material(
        WireframeMaterial::new(@color.Color::white(), 1.0F, Triangles),
      ),
    ),
  )
  let quads = WireframePipelineKey::from_material(
    mesh_key,
    Some(
      RenderWireframeMaterial::from_material(
        WireframeMaterial::new(@color.Color::white(), 1.0F, Quads),
      ),
    ),
  )
  let thick = WireframePipelineKey::from_material(
    mesh_key,
    Some(
      RenderWireframeMaterial::from_material(
        WireframeMaterial::new(@color.Color::white(), 3.0F, Triangles),
      ),
    ),
  )

  debug_inspect(thin.wide(), content="false")
  debug_inspect(thin.quads(), content="false")
  debug_inspect(thin.line_mode(), content="false")
  debug_inspect(quads.wide(), content="true")
  debug_inspect(quads.quads(), content="true")
  debug_inspect(quads.line_mode(), content="true")
  debug_inspect(thick.wide(), content="true")
  debug_inspect(thick.quads(), content="false")
  debug_inspect(thick.line_mode(), content="false")
}

///|
test "pbr: SpecializedWireframePipelineCache stores per-view and wide pipelines" {
  let cache = SpecializedWireframePipelineCache::SpecializedWireframePipelineCache()
  let view = @core.Entity::new(10, 1)
  let stale_view = @core.Entity::new(12, 1)
  let entity = @core.Entity::new(11, 1)
  let stale_entity = @core.Entity::new(13, 1)
  let main_entity = wireframe_test_main_entity(entity)
  let stale_main_entity = wireframe_test_main_entity(stale_entity)
  let pipeline = @material.CachedRenderPipelineId::new(77UL)
  cache.insert(view, main_entity, pipeline)
  cache.insert(
    stale_view,
    stale_main_entity,
    @material.CachedRenderPipelineId::new(79UL),
  )

  debug_inspect(cache.len(), content="2")
  debug_inspect(
    cache.pipeline_id(view, main_entity).map(fn(id) { id.id() }),
    content="Some(77)",
  )
  debug_inspect(cache.remove_from_view(view, main_entity), content="true")
  debug_inspect(cache.pipeline_id(view, main_entity) is None, content="true")
  cache.insert(view, main_entity, pipeline)
  cache.clear_view(view)
  debug_inspect(cache.pipeline_id(view, main_entity) is None, content="true")
  debug_inspect(
    cache.pipeline_id(stale_view, stale_main_entity) is Some(_),
    content="true",
  )

  let live : Map[UInt64, Bool] = {}
  live.set(view.to_bits(), true)
  cache.expire_stale_views(live)
  debug_inspect(cache.contains_view(view), content="true")
  debug_inspect(cache.contains_view(stale_view), content="false")

  let wide_key = WireframeWidePipelineCacheKey::new(
    @material.ErasedMeshPipelineKey::new(3UL, "MeshPipelineKey"),
    @render_mesh.RenderMesh::new(vertex_count=3).layout(),
    true,
    true,
  )
  cache.insert_wide_pipeline(
    wide_key,
    @material.CachedRenderPipelineId::new(88UL),
  )
  debug_inspect(cache.wide_len(), content="1")
  debug_inspect(
    cache.wide_pipeline_id(wide_key).map(fn(id) { id.id() }),
    content="Some(88)",
  )
}

///|
test "pbr: specialize wireframes keeps unloaded meshes in pending queues" {
  let view = @core.Entity::new(10, 1)
  let render_entity = @core.Entity::new(20, 1)
  let main_entity = wireframe_test_main_entity(@core.Entity::new(21, 1))
  let visible = @render_visibility.RenderVisibleEntitiesClass::RenderVisibleEntitiesClass()
  visible.update_cpu_culled_entities([(render_entity, main_entity)])
  let pending = ViewPendingWireframeQueues::ViewPendingWireframeQueues()
  let cache = SpecializedWireframePipelineCache::SpecializedWireframePipelineCache()
  let pipelines = SpecializedWireframeMeshPipelines::SpecializedWireframeMeshPipelines()
  let instances = RenderWireframeInstances::RenderWireframeInstances()
  instances.insert(main_entity, 8)

  specialize_wireframe_phase_items(
    view,
    visible,
    pending,
    cache,
    pipelines,
    instances,
    DirtyWireframeSpecializations::DirtyWireframeSpecializations(),
    {},
    RenderMeshInstances::new(),
    {},
    Wireframe3dPipeline::new(),
    @render_resource.PipelineCache::new(),
  )

  debug_inspect(cache.pipeline_id(view, main_entity) is None, content="true")
  debug_inspect(pending.current_len(), content="1")
}

///|
test "pbr: specialize wireframes caches thin pipelines by mesh layout and key" {
  let view = @core.Entity::new(10, 1)
  let first_render_entity = @core.Entity::new(20, 1)
  let second_render_entity = @core.Entity::new(22, 1)
  let first_main_entity = wireframe_test_main_entity(@core.Entity::new(21, 1))
  let second_main_entity = wireframe_test_main_entity(@core.Entity::new(23, 1))
  let visible = @render_visibility.RenderVisibleEntitiesClass::RenderVisibleEntitiesClass()
  visible.update_cpu_culled_entities([
    (first_render_entity, first_main_entity),
    (second_render_entity, second_main_entity),
  ])
  let pending = ViewPendingWireframeQueues::ViewPendingWireframeQueues()
  let cache = SpecializedWireframePipelineCache::SpecializedWireframePipelineCache()
  let pipelines = SpecializedWireframeMeshPipelines::SpecializedWireframeMeshPipelines()
  let instances = RenderWireframeInstances::RenderWireframeInstances()
  instances.insert(first_main_entity, 8)
  instances.insert(second_main_entity, 8)
  let render_mesh_instances = RenderMeshInstances::new()
  render_mesh_instances.insert(
    first_main_entity,
    RenderMeshQueueData::new(33, 1U, true),
  )
  render_mesh_instances.insert(
    second_main_entity,
    RenderMeshQueueData::new(33, 2U, true),
  )
  let render_mesh = @render_mesh.RenderMesh::new(vertex_count=3)
  let pipeline_data : Map[Int, WireframeRenderMeshPipelineData] = {}
  pipeline_data.set(
    33,
    wireframe_mesh_pipeline_data_for_render_mesh(
      render_mesh,
      wireframe_phase_test_descriptor(),
      view_key_bits=0UL,
    ),
  )
  let pipeline_cache = @render_resource.PipelineCache::new()

  specialize_wireframe_phase_items(
    view,
    visible,
    pending,
    cache,
    pipelines,
    instances,
    DirtyWireframeSpecializations::DirtyWireframeSpecializations(),
    {},
    render_mesh_instances,
    pipeline_data,
    Wireframe3dPipeline::new(),
    pipeline_cache,
  )

  debug_inspect(pipelines.len(), content="1")
  debug_inspect(cache.wide_len(), content="0")
  debug_inspect(pipeline_cache.queued_pipeline_count(), content="1")
  debug_inspect(
    cache.pipeline_id(view, first_main_entity).map(fn(id) { id.id() }),
    content="Some(0)",
  )
  debug_inspect(
    cache.pipeline_id(view, second_main_entity).map(fn(id) { id.id() }),
    content="Some(0)",
  )
  debug_inspect(pending.current_len(), content="0")
}

///|
test "pbr: specialize wireframes includes previous skin and morph flags per instance" {
  let view = @core.Entity::new(10, 1)
  let first_render_entity = @core.Entity::new(20, 1)
  let second_render_entity = @core.Entity::new(22, 1)
  let first_main_entity = wireframe_test_main_entity(@core.Entity::new(21, 1))
  let second_main_entity = wireframe_test_main_entity(@core.Entity::new(23, 1))
  let visible = @render_visibility.RenderVisibleEntitiesClass::RenderVisibleEntitiesClass()
  visible.update_cpu_culled_entities([
    (first_render_entity, first_main_entity),
    (second_render_entity, second_main_entity),
  ])
  let pending = ViewPendingWireframeQueues::ViewPendingWireframeQueues()
  let cache = SpecializedWireframePipelineCache::SpecializedWireframePipelineCache()
  let pipelines = SpecializedWireframeMeshPipelines::SpecializedWireframeMeshPipelines()
  let instances = RenderWireframeInstances::RenderWireframeInstances()
  instances.insert(first_main_entity, 8)
  instances.insert(second_main_entity, 8)
  let render_mesh_instances = RenderMeshInstances::new()
  render_mesh_instances.insert(
    first_main_entity,
    RenderMeshQueueData::new(
      33,
      1U,
      true,
      flags=RenderMeshInstanceFlags::has_previous_skin(),
    ),
  )
  render_mesh_instances.insert(
    second_main_entity,
    RenderMeshQueueData::new(
      33,
      2U,
      true,
      flags=RenderMeshInstanceFlags::has_previous_morph(),
    ),
  )
  let render_mesh = @render_mesh.RenderMesh::new(vertex_count=3)
  let pipeline_data : Map[Int, WireframeRenderMeshPipelineData] = {}
  pipeline_data.set(
    33,
    wireframe_mesh_pipeline_data_for_render_mesh(
      render_mesh,
      wireframe_phase_test_descriptor(),
      view_key_bits=MESH_PIPELINE_KEY_MOTION_VECTOR_PREPASS,
    ),
  )
  let pipeline_cache = @render_resource.PipelineCache::new()

  specialize_wireframe_phase_items(
    view,
    visible,
    pending,
    cache,
    pipelines,
    instances,
    DirtyWireframeSpecializations::DirtyWireframeSpecializations(),
    {},
    render_mesh_instances,
    pipeline_data,
    Wireframe3dPipeline::new(),
    pipeline_cache,
  )

  debug_inspect(pipelines.len(), content="2")
  debug_inspect(pipeline_cache.queued_pipeline_count(), content="2")
  debug_inspect(
    cache.pipeline_id(view, first_main_entity).map(fn(id) { id.id() }),
    content="Some(0)",
  )
  debug_inspect(
    cache.pipeline_id(view, second_main_entity).map(fn(id) { id.id() }),
    content="Some(1)",
  )
}

///|
test "pbr: specialize wireframes uses Bevy wide cache key and invalid fallback" {
  let view = @core.Entity::new(10, 1)
  let render_entity = @core.Entity::new(20, 1)
  let main_entity = wireframe_test_main_entity(@core.Entity::new(21, 1))
  let visible = @render_visibility.RenderVisibleEntitiesClass::RenderVisibleEntitiesClass()
  visible.update_cpu_culled_entities([(render_entity, main_entity)])
  let pending = ViewPendingWireframeQueues::ViewPendingWireframeQueues()
  let cache = SpecializedWireframePipelineCache::SpecializedWireframePipelineCache()
  let pipelines = SpecializedWireframeMeshPipelines::SpecializedWireframeMeshPipelines()
  let instances = RenderWireframeInstances::RenderWireframeInstances()
  instances.insert(main_entity, 8)
  let materials : Map[Int, RenderWireframeMaterial] = {}
  materials.set(
    8,
    RenderWireframeMaterial::from_material(
      WireframeMaterial::new(@color.Color::white(), 1.0F, Quads),
    ),
  )
  let render_mesh_instances = RenderMeshInstances::new()
  render_mesh_instances.insert(
    main_entity,
    RenderMeshQueueData::new(33, 1U, true),
  )
  let render_mesh = @render_mesh.RenderMesh::new(vertex_count=3)
  let pipeline_data : Map[Int, WireframeRenderMeshPipelineData] = {}
  pipeline_data.set(
    33,
    wireframe_mesh_pipeline_data_for_render_mesh(
      render_mesh,
      @material.RenderPipelineDescriptor::RenderPipelineDescriptor(),
      view_key_bits=0UL,
    ),
  )

  specialize_wireframe_phase_items(
    view,
    visible,
    pending,
    cache,
    pipelines,
    instances,
    DirtyWireframeSpecializations::DirtyWireframeSpecializations(),
    materials,
    render_mesh_instances,
    pipeline_data,
    Wireframe3dPipeline::new(),
    @render_resource.PipelineCache::new(),
  )

  debug_inspect(pipelines.len(), content="0")
  debug_inspect(cache.wide_len(), content="1")
  debug_inspect(
    cache.pipeline_id(view, main_entity).map(fn(id) { id.id() }),
    content="Some(18446744073709551615)",
  )
}

///|
test "pbr: PendingWireframeQueues moves per-view current frame into prev frame" {
  let queues = PendingWireframeQueues::PendingWireframeQueues()
  let view_a = @core.Entity::new(10, 1)
  let view_b = @core.Entity::new(11, 1)
  queues.push_current(
    view_a,
    @core.Entity::new(1, 1),
    wireframe_test_main_entity(@core.Entity::new(2, 1)),
  )
  queues.push_current(
    view_a,
    @core.Entity::new(1, 1),
    wireframe_test_main_entity(@core.Entity::new(2, 1)),
  )
  queues.push_current(
    view_a,
    @core.Entity::new(3, 1),
    wireframe_test_main_entity(@core.Entity::new(4, 1)),
  )
  queues.push_current(
    view_b,
    @core.Entity::new(5, 1),
    wireframe_test_main_entity(@core.Entity::new(6, 1)),
  )
  debug_inspect(queues.view_len(), content="2")
  debug_inspect(queues.current_len(view_a), content="2")
  debug_inspect(queues.current_len(view_b), content="1")
  debug_inspect(queues.prev_len(view_a), content="0")

  let view_a_queues = queues.prepare_for_new_frame(view_a)

  debug_inspect(view_a_queues.current_len(), content="0")
  debug_inspect(view_a_queues.prev_len(), content="2")
  debug_inspect(queues.current_len(view_a), content="0")
  debug_inspect(queues.prev_len(view_a), content="2")
  debug_inspect(queues.current_len(view_b), content="1")
  debug_inspect(queues.prev_len(view_b), content="0")
}

///|
test "pbr: PendingWireframeQueues expires stale views" {
  let queues = PendingWireframeQueues::PendingWireframeQueues()
  let live_view = @core.Entity::new(10, 1)
  let stale_view = @core.Entity::new(11, 1)
  queues.push_current(
    live_view,
    @core.Entity::new(1, 1),
    wireframe_test_main_entity(@core.Entity::new(2, 1)),
  )
  queues.push_current(
    stale_view,
    @core.Entity::new(3, 1),
    wireframe_test_main_entity(@core.Entity::new(4, 1)),
  )
  let live : Map[UInt64, Bool] = {}
  live.set(live_view.to_bits(), true)

  queues.expire_stale_views(live)

  debug_inspect(queues.view_len(), content="1")
  debug_inspect(queues.contains_view(live_view), content="true")
  debug_inspect(queues.contains_view(stale_view), content="false")
}

///|
test "pbr: render wireframe instance resources track Bevy render asset ids" {
  let instances = RenderWireframeInstances::RenderWireframeInstances()
  let entity = @core.Entity::new(7, 1)
  let main_entity = wireframe_test_main_entity(entity)
  instances.insert(main_entity, 42)
  debug_inspect(instances.len(), content="1")
  debug_inspect(instances.get(main_entity), content="Some(42)")
  debug_inspect(instances.remove(main_entity), content="true")
  debug_inspect(instances.get(main_entity), content="None")
  instances.insert(main_entity, 77)
  instances.clear()
  debug_inspect(instances.len(), content="0")
  debug_inspect(instances.get(main_entity), content="None")
}

///|
test "pbr: extract_wireframe_materials mirrors visible Mesh3dWireframe changes" {
  let source_world = @ecs.World::new()
  let instances = RenderWireframeInstances::RenderWireframeInstances()
  let visible_entity = source_world.spawn()
  let hidden_entity = source_world.spawn()
  instances.insert(wireframe_test_main_entity(hidden_entity), 99)
  try! source_world.set_by_key(
    visible_entity,
    @visibility.ecs_key_view_visibility,
    @visibility.ViewVisibility::new(true),
  )
  try! source_world.set_by_key(
    visible_entity,
    ecs_key_mesh3d_wireframe,
    Mesh3dWireframe::new(@asset.Handle::new(42)),
  )
  try! source_world.set_by_key(
    hidden_entity,
    @visibility.ecs_key_view_visibility,
    @visibility.ViewVisibility::new(false),
  )
  try! source_world.set_by_key(
    hidden_entity,
    ecs_key_mesh3d_wireframe,
    Mesh3dWireframe::new(@asset.Handle::new(13)),
  )

  extract_wireframe_materials_from_world(
    source_world,
    instances,
    @core.SystemTicks::new(0, 1),
  )

  debug_inspect(instances.len(), content="1")
  debug_inspect(
    instances.get(wireframe_test_main_entity(visible_entity)),
    content="Some(42)",
  )
  debug_inspect(
    instances.get(wireframe_test_main_entity(hidden_entity)),
    content="None",
  )
}

///|
test "pbr: extract_wireframe_materials removes stale removed components" {
  let source_world = @ecs.World::new()
  let instances = RenderWireframeInstances::RenderWireframeInstances()
  let entity = source_world.spawn()
  try! source_world.set_by_key(
    entity,
    @visibility.ecs_key_view_visibility,
    @visibility.ViewVisibility::new(true),
  )
  try! source_world.set_by_key(
    entity,
    ecs_key_mesh3d_wireframe,
    Mesh3dWireframe::new(@asset.Handle::new(7)),
  )
  extract_wireframe_materials_from_world(
    source_world,
    instances,
    @core.SystemTicks::new(0, 1),
  )
  debug_inspect(
    instances.get(wireframe_test_main_entity(entity)),
    content="Some(7)",
  )

  source_world.increment_change_tick() |> ignore
  source_world.increment_change_tick() |> ignore
  try! (source_world.remove_by_key(entity, ecs_key_mesh3d_wireframe) |> ignore)
  extract_wireframe_materials_from_world(
    source_world,
    instances,
    @core.SystemTicks::new(1, 2),
  )

  debug_inspect(
    instances.get(wireframe_test_main_entity(entity)),
    content="None",
  )
}

///|
test "pbr: extract_wireframe_materials preserves same-frame readded material" {
  let source_world = @ecs.World::new()
  let instances = RenderWireframeInstances::RenderWireframeInstances()
  let entity = source_world.spawn()
  try! source_world.set_by_key(
    entity,
    @visibility.ecs_key_view_visibility,
    @visibility.ViewVisibility::new(true),
  )
  try! source_world.set_by_key(
    entity,
    ecs_key_mesh3d_wireframe,
    Mesh3dWireframe::new(@asset.Handle::new(3)),
  )
  extract_wireframe_materials_from_world(
    source_world,
    instances,
    @core.SystemTicks::new(0, 1),
  )
  debug_inspect(
    instances.get(wireframe_test_main_entity(entity)),
    content="Some(3)",
  )

  source_world.increment_change_tick() |> ignore
  source_world.increment_change_tick() |> ignore
  try! (source_world.remove_by_key(entity, ecs_key_mesh3d_wireframe) |> ignore)
  try! source_world.set_by_key(
    entity,
    ecs_key_mesh3d_wireframe,
    Mesh3dWireframe::new(@asset.Handle::new(11)),
  )
  extract_wireframe_materials_from_world(
    source_world,
    instances,
    @core.SystemTicks::new(1, 2),
  )

  debug_inspect(
    instances.get(wireframe_test_main_entity(entity)),
    content="Some(11)",
  )
}

///|
test "pbr: wireframe specialization check collects changed source entities" {
  let world = @ecs.World::new()
  let needs = WireframeEntitiesNeedingSpecialization::WireframeEntitiesNeedingSpecialization()
  let mesh_entity = world.spawn()
  let material_entity = world.spawn()
  let width_entity = world.spawn()
  let topology_entity = world.spawn()
  try! world.set_by_key(
    mesh_entity,
    ecs_key_mesh3d,
    @mesh.Mesh3d::new(@asset.Handle::new(1)),
  )
  try! world.set_by_key(
    material_entity,
    ecs_key_mesh3d_wireframe,
    Mesh3dWireframe::new(@asset.Handle::new(2)),
  )
  try! world.set_by_key(
    width_entity,
    ecs_key_wireframe_line_width,
    WireframeLineWidth::new(3.0F),
  )
  try! world.set_by_key(topology_entity, ecs_key_wireframe_topology, Quads)

  check_wireframe_entities_needing_specialization_from_world(
    world,
    needs,
    @core.SystemTicks::new(0, 1),
  )

  debug_inspect(needs.changed_len(), content="4")
  debug_inspect(needs.changed_contains(mesh_entity), content="true")
  debug_inspect(needs.changed_contains(material_entity), content="true")
  debug_inspect(needs.changed_contains(width_entity), content="true")
  debug_inspect(needs.changed_contains(topology_entity), content="true")
  debug_inspect(needs.removed_len(), content="0")
}

///|
test "pbr: wireframe specialization check tracks material asset changes once" {
  let world = @ecs.World::new()
  init_wireframe_resources(world)
  let asset_key : @ecs.ResourceKey[@asset.Assets[WireframeMaterial]] = @asset.assets_resource_key()
  let source_assets : @asset.Assets[WireframeMaterial] = @asset.Assets::new()
  let material_handle = source_assets.add(
    WireframeMaterial::new(@color.Color::white(), 1.0F, Triangles),
  )
  world.insert_resource(asset_key, source_assets)
  @asset.asset_update_event_messages(world)
  let entity = world.spawn()
  try! world.set_by_key(
    entity,
    ecs_key_mesh3d_wireframe,
    Mesh3dWireframe::new(material_handle),
  )
  world.increment_change_tick() |> ignore
  world.increment_change_tick() |> ignore
  let needs = WireframeEntitiesNeedingSpecialization::WireframeEntitiesNeedingSpecialization()

  check_wireframe_entities_needing_specialization_from_world(
    world,
    needs,
    @core.SystemTicks::new(1, 2),
  )

  debug_inspect(needs.changed_len(), content="1")
  debug_inspect(needs.changed_contains(entity), content="true")

  check_wireframe_entities_needing_specialization_from_world(
    world,
    needs,
    @core.SystemTicks::new(1, 2),
  )

  debug_inspect(needs.changed_len(), content="0")

  match world.get_resource_mut(asset_key) {
    Some(assets) =>
      assets.modify(fn(value) {
        ignore(
          value.set(
            material_handle,
            WireframeMaterial::new(@color.Color::white(), 3.0F, Quads),
          ),
        )
      })
    None => abort("missing WireframeMaterial assets")
  }
  @asset.asset_update_event_messages(world)

  check_wireframe_entities_needing_specialization_from_world(
    world,
    needs,
    @core.SystemTicks::new(1, 2),
  )

  debug_inspect(needs.changed_len(), content="1")
  debug_inspect(needs.changed_contains(entity), content="true")
}

///|
test "pbr: wireframe specialization check tracks mesh asset changes once" {
  let world = @ecs.World::new()
  init_wireframe_resources(world)
  let asset_key : @ecs.ResourceKey[@asset.Assets[@mesh.Mesh]] = @asset.assets_resource_key()
  let source_assets : @asset.Assets[@mesh.Mesh] = @asset.Assets::new()
  let mesh_handle = source_assets.add(
    @mesh.Mesh::from_3d_geometry(@mesh.Mesh3dGeometry::new([], [], None)),
  )
  world.insert_resource(asset_key, source_assets)
  @asset.asset_update_event_messages(world)
  let entity = world.spawn()
  try! world.set_by_key(entity, ecs_key_mesh3d, @mesh.Mesh3d::new(mesh_handle))
  world.increment_change_tick() |> ignore
  world.increment_change_tick() |> ignore
  let needs = WireframeEntitiesNeedingSpecialization::WireframeEntitiesNeedingSpecialization()

  check_wireframe_entities_needing_specialization_from_world(
    world,
    needs,
    @core.SystemTicks::new(1, 2),
  )

  debug_inspect(needs.changed_len(), content="1")
  debug_inspect(needs.changed_contains(entity), content="true")

  check_wireframe_entities_needing_specialization_from_world(
    world,
    needs,
    @core.SystemTicks::new(1, 2),
  )

  debug_inspect(needs.changed_len(), content="0")

  match world.get_resource_mut(asset_key) {
    Some(assets) =>
      assets.modify(fn(value) {
        ignore(
          value.set(
            mesh_handle,
            @mesh.Mesh::from_3d_geometry(
              @mesh.Mesh3dGeometry::new([], [], None),
            ),
          ),
        )
      })
    None => abort("missing Mesh assets")
  }
  @asset.asset_update_event_messages(world)

  check_wireframe_entities_needing_specialization_from_world(
    world,
    needs,
    @core.SystemTicks::new(1, 2),
  )

  debug_inspect(needs.changed_len(), content="1")
  debug_inspect(needs.changed_contains(entity), content="true")
}

///|
test "pbr: wireframe specialization check collects removed source entities" {
  let world = @ecs.World::new()
  let needs = WireframeEntitiesNeedingSpecialization::WireframeEntitiesNeedingSpecialization()
  let mesh_entity = world.spawn()
  let material_entity = world.spawn()
  try! world.set_by_key(
    mesh_entity,
    ecs_key_mesh3d,
    @mesh.Mesh3d::new(@asset.Handle::new(1)),
  )
  try! world.set_by_key(
    material_entity,
    ecs_key_mesh3d_wireframe,
    Mesh3dWireframe::new(@asset.Handle::new(2)),
  )
  world.increment_change_tick() |> ignore
  world.increment_change_tick() |> ignore
  try! (world.remove_by_key(mesh_entity, ecs_key_mesh3d) |> ignore)
  try! (world.remove_by_key(material_entity, ecs_key_mesh3d_wireframe) |> ignore)

  check_wireframe_entities_needing_specialization_from_world(
    world,
    needs,
    @core.SystemTicks::new(1, 2),
  )

  debug_inspect(needs.changed_len(), content="0")
  debug_inspect(needs.removed_len(), content="2")
  debug_inspect(needs.removed_contains(mesh_entity), content="true")
  debug_inspect(needs.removed_contains(material_entity), content="true")
}

///|
test "pbr: dirty wireframe specializations mirror Bevy dirty tables" {
  let dirty = DirtyWireframeSpecializations::DirtyWireframeSpecializations()
  let changed_entity = @core.Entity::new(1, 1)
  let removed_entity = @core.Entity::new(2, 1)
  let changed_main_entity = wireframe_test_main_entity(changed_entity)
  let removed_main_entity = wireframe_test_main_entity(removed_entity)
  dirty.insert_changed(changed_main_entity)
  dirty.insert_removed(removed_main_entity)
  debug_inspect(dirty.changed_len(), content="1")
  debug_inspect(dirty.removed_len(), content="1")
  debug_inspect(dirty.changed_contains(changed_main_entity), content="true")
  debug_inspect(dirty.removed_contains(removed_main_entity), content="true")

  dirty.clear()

  debug_inspect(dirty.changed_len(), content="0")
  debug_inspect(dirty.removed_len(), content="0")
}

///|
test "pbr: dirty wireframe specializations expose Bevy despecialize helpers" {
  let dirty = DirtyWireframeSpecializations::DirtyWireframeSpecializations()
  let changed_entity = @core.Entity::new(1, 1)
  let removed_entity = @core.Entity::new(2, 1)
  let changed_main_entity = wireframe_test_main_entity(changed_entity)
  let removed_main_entity = wireframe_test_main_entity(removed_entity)
  let view = @core.Entity::new(3, 1)
  dirty.insert_changed(changed_main_entity)
  dirty.insert_removed(removed_main_entity)
  dirty.insert_view(view)

  let to_despecialize = dirty.to_despecialize()

  debug_inspect(to_despecialize.length(), content="2")
  debug_inspect(to_despecialize.contains(changed_main_entity), content="true")
  debug_inspect(to_despecialize.contains(removed_main_entity), content="true")
  debug_inspect(dirty.views_len(), content="1")
  debug_inspect(dirty.must_wipe_specializations_for_view(view), content="true")
  debug_inspect(
    dirty.must_wipe_specializations_for_view(@core.Entity::new(4, 1)),
    content="false",
  )

  dirty.clear()

  debug_inspect(dirty.views_len(), content="0")
  debug_inspect(to_despecialize.length(), content="2")
  debug_inspect(dirty.to_despecialize().length(), content="0")
}

///|
test "pbr: despecialize_wireframe_view_cache follows Bevy dirty removal branch" {
  let cache = SpecializedWireframePipelineCache::SpecializedWireframePipelineCache()
  let dirty = DirtyWireframeSpecializations::DirtyWireframeSpecializations()
  let view = @core.Entity::new(10, 1)
  let changed_entity = @core.Entity::new(11, 1)
  let removed_entity = @core.Entity::new(12, 1)
  let stable_entity = @core.Entity::new(13, 1)
  let changed_main_entity = wireframe_test_main_entity(changed_entity)
  let removed_main_entity = wireframe_test_main_entity(removed_entity)
  let stable_main_entity = wireframe_test_main_entity(stable_entity)
  cache.insert(
    view,
    changed_main_entity,
    @material.CachedRenderPipelineId::new(1UL),
  )
  cache.insert(
    view,
    removed_main_entity,
    @material.CachedRenderPipelineId::new(2UL),
  )
  cache.insert(
    view,
    stable_main_entity,
    @material.CachedRenderPipelineId::new(3UL),
  )
  dirty.insert_changed(changed_main_entity)
  dirty.insert_removed(removed_main_entity)

  despecialize_wireframe_view_cache(cache, dirty, view)

  debug_inspect(
    cache.pipeline_id(view, changed_main_entity) is None,
    content="true",
  )
  debug_inspect(
    cache.pipeline_id(view, removed_main_entity) is None,
    content="true",
  )
  debug_inspect(
    cache.pipeline_id(view, stable_main_entity).map(fn(id) { id.id() }),
    content="Some(3)",
  )

  dirty.insert_view(view)
  despecialize_wireframe_view_cache(cache, dirty, view)

  debug_inspect(
    cache.pipeline_id(view, stable_main_entity) is None,
    content="true",
  )
}

///|
test "pbr: dirty wireframe specializations iterate Bevy specialize queue" {
  let dirty = DirtyWireframeSpecializations::DirtyWireframeSpecializations()
  let view = @core.Entity::new(10, 1)
  let visible = @render_visibility.RenderVisibleEntitiesClass::RenderVisibleEntitiesClass()
  let stable_pair = (
    @core.Entity::new(20, 1),
    wireframe_test_main_entity(@core.Entity::new(21, 1)),
  )
  let pending_pair = (
    @core.Entity::new(30, 1),
    wireframe_test_main_entity(@core.Entity::new(31, 1)),
  )
  let added_pair = (
    @core.Entity::new(40, 1),
    wireframe_test_main_entity(@core.Entity::new(41, 1)),
  )
  visible.update_cpu_culled_entities([stable_pair, pending_pair])
  visible.prepare_for_new_frame()
  visible.update_cpu_culled_entities([stable_pair, pending_pair, added_pair])
  dirty.insert_changed(stable_pair.1)
  let pending : @hashset.HashSet[(@core.Entity, @render.MainEntity)] = @hashset.HashSet([],
  )
  pending.add(pending_pair)

  let to_specialize = dirty.iter_to_specialize(view, visible, pending)

  debug_inspect(to_specialize.length(), content="3")
  debug_inspect(to_specialize.contains(added_pair), content="true")
  debug_inspect(to_specialize.contains(stable_pair), content="true")
  debug_inspect(to_specialize.contains(pending_pair), content="true")
}

///|
test "pbr: dirty wireframe specializations iterate Bevy dequeue and queue lists" {
  let dirty = DirtyWireframeSpecializations::DirtyWireframeSpecializations()
  let view = @core.Entity::new(10, 1)
  let visible = @render_visibility.RenderVisibleEntitiesClass::RenderVisibleEntitiesClass()
  let removed_pair = (
    @core.Entity::new(20, 1),
    wireframe_test_main_entity(@core.Entity::new(21, 1)),
  )
  let changed_pair = (
    @core.Entity::new(30, 1),
    wireframe_test_main_entity(@core.Entity::new(31, 1)),
  )
  let added_pair = (
    @core.Entity::new(40, 1),
    wireframe_test_main_entity(@core.Entity::new(41, 1)),
  )
  let pending_pair = (
    @core.Entity::new(50, 1),
    wireframe_test_main_entity(@core.Entity::new(51, 1)),
  )
  let explicitly_removed = wireframe_test_main_entity(@core.Entity::new(61, 1))
  visible.update_cpu_culled_entities([removed_pair, changed_pair, pending_pair])
  visible.prepare_for_new_frame()
  visible.update_cpu_culled_entities([changed_pair, pending_pair, added_pair])
  dirty.insert_changed(changed_pair.1)
  dirty.insert_removed(explicitly_removed)
  let pending : @hashset.HashSet[(@core.Entity, @render.MainEntity)] = @hashset.HashSet([],
  )
  pending.add(pending_pair)

  let to_dequeue = dirty.iter_to_dequeue(view, visible)
  let to_queue = dirty.iter_to_queue(view, visible, pending)

  debug_inspect(to_dequeue.length(), content="3")
  debug_inspect(to_dequeue.contains(removed_pair.1), content="true")
  debug_inspect(to_dequeue.contains(changed_pair.1), content="true")
  debug_inspect(to_dequeue.contains(explicitly_removed), content="true")
  debug_inspect(to_queue.length(), content="3")
  debug_inspect(to_queue.contains(added_pair), content="true")
  debug_inspect(to_queue.contains(changed_pair), content="true")
  debug_inspect(to_queue.contains(pending_pair), content="true")
}

///|
test "pbr: wireframe dirty extraction writes changed and removed render tables" {
  let world = @ecs.World::new()
  let changed_entity = @core.Entity::new(3, 1)
  let removed_entity = @core.Entity::new(4, 1)
  let needs = WireframeEntitiesNeedingSpecialization::WireframeEntitiesNeedingSpecialization()
  needs.changed.push(changed_entity)
  needs.removed.push(removed_entity)
  world.insert_resource(
    WireframeEntitiesNeedingSpecialization::resource(),
    needs,
  )
  world.insert_resource(
    DirtyWireframeSpecializations::resource(),
    DirtyWireframeSpecializations::DirtyWireframeSpecializations(),
  )

  extract_wireframe_entities_needing_specialization_system(world)
  extract_wireframe_entities_that_need_specializations_removed_system(world)

  let dirty = match
    world.get_resource(DirtyWireframeSpecializations::resource()) {
    Some(value) => value
    None => abort("missing DirtyWireframeSpecializations")
  }
  debug_inspect(dirty.changed_len(), content="1")
  debug_inspect(dirty.removed_len(), content="1")
  debug_inspect(
    dirty.changed_contains(wireframe_test_main_entity(changed_entity)),
    content="true",
  )
  debug_inspect(
    dirty.removed_contains(wireframe_test_main_entity(removed_entity)),
    content="true",
  )
}

///|
test "pbr: wireframe 3d phases prepare and retain views" {
  let phases = Wireframe3dPhases::Wireframe3dPhases()
  let live_view = @core.Entity::new(10, 1)
  let stale_view = @core.Entity::new(11, 1)
  phases.prepare_for_new_frame(
    live_view,
    @render_batching.GpuPreprocessingMode::None,
  )
  phases.prepare_for_new_frame(
    stale_view,
    @render_batching.GpuPreprocessingMode::Culling,
  )
  let live : Map[UInt64, Bool] = {}
  live.set(live_view.to_bits(), true)

  phases.retain_live_views(live)

  debug_inspect(phases.len(), content="1")
  debug_inspect(phases.contains(live_view), content="true")
  debug_inspect(phases.contains(stale_view), content="false")
  debug_inspect(
    phases.phase(live_view).map(fn(phase) { phase.gpu_preprocessing_mode() }),
    content="Some(None)",
  )
}

///|
test "pbr: wireframe binned phase type follows Bevy mesh helper" {
  let support = @render_batching.GpuPreprocessingSupport::GpuPreprocessingSupport()
  debug_inspect(
    WireframeBinnedRenderPhaseType::mesh(true, support),
    content="BatchableMesh",
  )
  debug_inspect(
    WireframeBinnedRenderPhaseType::mesh(false, support),
    content="UnbatchableMesh",
  )
}

///|
test "pbr: wireframe view phase add caches Bevy bin metadata" {
  let phases = Wireframe3dPhases::Wireframe3dPhases()
  let view = @core.Entity::new(10, 1)
  let render_entity = @core.Entity::new(20, 1)
  let main_entity = wireframe_test_main_entity(@core.Entity::new(21, 1))
  phases.prepare_for_new_frame(
    view,
    @render_batching.GpuPreprocessingMode::PreprocessingOnly,
  )
  let batch_set = Wireframe3dBatchSetKey::new(
    @material.CachedRenderPipelineId::new(77UL),
    8,
    @material.DrawFunctionId::new(3U),
    @render_mesh.MeshSlabs::new(2, index_slab_id=Some(5)),
  )
  let bin = Wireframe3dBinKey::new(8)

  phases.add(
    view,
    batch_set,
    bin,
    (render_entity, main_entity),
    9U,
    MultidrawableMesh,
  )

  let phase = match phases.phase(view) {
    Some(value) => value
    None => abort("missing wireframe view phase")
  }
  debug_inspect(phase.len(), content="1")
  debug_inspect(phase.is_empty(), content="false")
  debug_inspect(phase.input_uniform_index(main_entity), content="Some(9)")
  debug_inspect(phase.phase_type(main_entity), content="Some(BatchableMesh)")

  phases.remove(view, main_entity)
  debug_inspect(phase.len(), content="0")
  debug_inspect(phase.input_uniform_index(main_entity), content="None")
  debug_inspect(phase.phase_type(main_entity), content="None")
}

///|
test "pbr: queue wireframes keeps unloaded meshes in pending queues" {
  let view = @core.Entity::new(10, 1)
  let render_entity = @core.Entity::new(20, 1)
  let main_entity = wireframe_test_main_entity(@core.Entity::new(21, 1))
  let visible = @render_visibility.RenderVisibleEntitiesClass::RenderVisibleEntitiesClass()
  visible.update_cpu_culled_entities([(render_entity, main_entity)])
  let pending = ViewPendingWireframeQueues::ViewPendingWireframeQueues()
  let cache = SpecializedWireframePipelineCache::SpecializedWireframePipelineCache()
  cache.insert(view, main_entity, @material.CachedRenderPipelineId::new(77UL))
  let instances = RenderWireframeInstances::RenderWireframeInstances()
  instances.insert(main_entity, 8)
  let phase = Wireframe3dViewPhase::new(
    @render_batching.GpuPreprocessingMode::None,
  )

  queue_wireframe_phase_items(
    phase,
    view,
    visible,
    pending,
    cache,
    instances,
    DirtyWireframeSpecializations::DirtyWireframeSpecializations(),
    {},
    RenderMeshInstances::new(),
    @render_mesh.MeshAllocator::new(),
    Wireframe3dDrawFunctions::Wireframe3dDrawFunctions(),
    @render_batching.GpuPreprocessingSupport::GpuPreprocessingSupport(),
  )

  debug_inspect(phase.len(), content="0")
  debug_inspect(pending.current_len(), content="1")
}

///|
test "pbr: queue wireframes adds wide phase items with Bevy batch keys" {
  let view = @core.Entity::new(10, 1)
  let render_entity = @core.Entity::new(20, 1)
  let main_entity = wireframe_test_main_entity(@core.Entity::new(21, 1))
  let visible = @render_visibility.RenderVisibleEntitiesClass::RenderVisibleEntitiesClass()
  visible.update_cpu_culled_entities([(render_entity, main_entity)])
  let pending = ViewPendingWireframeQueues::ViewPendingWireframeQueues()
  let cache = SpecializedWireframePipelineCache::SpecializedWireframePipelineCache()
  cache.insert(view, main_entity, @material.CachedRenderPipelineId::new(77UL))
  let instances = RenderWireframeInstances::RenderWireframeInstances()
  instances.insert(main_entity, 8)
  let render_wireframe_assets : Map[Int, RenderWireframeMaterial] = {}
  render_wireframe_assets.set(
    8,
    RenderWireframeMaterial::from_material(
      WireframeMaterial::new(@color.Color::white(), 2.0F, Triangles),
    ),
  )
  let render_mesh_instances = RenderMeshInstances::new()
  render_mesh_instances.insert(
    main_entity,
    RenderMeshQueueData::new(33, 9U, true),
  )
  let mesh_allocator = @render_mesh.MeshAllocator::new()
  let _ = mesh_allocator.allocate_render_mesh(
    33,
    @render_mesh.RenderMesh::new(vertex_count=3, indexed=true, index_count=3),
    80,
  )
  let draw_functions = Wireframe3dDrawFunctions::Wireframe3dDrawFunctions()
  let phase = Wireframe3dViewPhase::new(
    @render_batching.GpuPreprocessingMode::None,
  )

  queue_wireframe_phase_items(
    phase,
    view,
    visible,
    pending,
    cache,
    instances,
    DirtyWireframeSpecializations::DirtyWireframeSpecializations(),
    render_wireframe_assets,
    render_mesh_instances,
    mesh_allocator,
    draw_functions,
    @render_batching.GpuPreprocessingSupport::GpuPreprocessingSupport(),
  )

  debug_inspect(phase.len(), content="1")
  let item = phase.items[0]
  debug_inspect(item.main_entity() == main_entity, content="true")
  debug_inspect(item.cached_pipeline().id(), content="77")
  debug_inspect(item.draw_function().id(), content="1")
  debug_inspect(item.bin_key().asset_id(), content="33")
  debug_inspect(item.batch_set_key().asset_id(), content="8")
  debug_inspect(item.batch_set_key().mesh_asset_id(), content="Some(33)")
  debug_inspect(item.batch_set_key().slabs().index_slab_id(), content="None")
  debug_inspect(
    item.batch_set_key().slabs().morph_target_slab_id(),
    content="None",
  )
  debug_inspect(phase.input_uniform_index(main_entity), content="Some(0)")
  debug_inspect(phase.phase_type(main_entity), content="Some(BatchableMesh)")
  debug_inspect(pending.current_len(), content="0")
}

///|
test "pbr: render wireframe assets mirror source WireframeMaterial assets" {
  let world = @ecs.World::new()
  let asset_key : @ecs.ResourceKey[@asset.Assets[WireframeMaterial]] = @asset.assets_resource_key()
  let source_assets : @asset.Assets[WireframeMaterial] = @asset.Assets::new()
  let handle = source_assets.add(
    WireframeMaterial::new(@color.Color::white(), 2.0F, Quads),
  )
  world.insert_resource(asset_key, source_assets)
  world.insert_resource(
    RenderWireframeAssets::resource(),
    RenderWireframeAssets::RenderWireframeAssets(),
  )

  extract_wireframe_material_assets_system(world)

  let render_assets = match
    world.get_resource(RenderWireframeAssets::resource()) {
    Some(value) => value
    None => abort("missing RenderWireframeAssets")
  }
  debug_inspect(render_assets.len(), content="1")
  let material = render_assets.get(handle.id()).unwrap()
  debug_inspect(material.line_width, content="2")
  debug_inspect(material.topology, content="Quads")
}

///|
test "pbr: wireframe render systems specialize and queue visible Mesh3d phase items" {
  let world = @ecs.World::new()
  let view = world.spawn()
  let render_entity = @core.Entity::new(20, 1)
  let main_entity = wireframe_test_main_entity(@core.Entity::new(21, 1))
  let visible_class = @render_visibility.RenderVisibleEntitiesClass::RenderVisibleEntitiesClass()
  visible_class.update_cpu_culled_entities([(render_entity, main_entity)])
  let visible_entities = @render_visibility.RenderVisibleEntities::RenderVisibleEntities()
  visible_entities.insert(wireframe_mesh_visibility_class(), visible_class)
  try! world.set_by_key(
    view, @render_visibility.ecs_key_render_visible_entities, visible_entities,
  )

  let phases = Wireframe3dPhases::Wireframe3dPhases()
  phases.prepare_for_new_frame(
    view,
    @render_batching.GpuPreprocessingMode::None,
  )
  world.insert_resource(Wireframe3dPhases::resource(), phases)
  let view_key_cache = WireframeViewKeyCache::WireframeViewKeyCache()
  view_key_cache.insert(view, 0UL)
  world.insert_resource(WireframeViewKeyCache::resource(), view_key_cache)
  world.insert_resource(
    PendingWireframeQueues::resource(),
    PendingWireframeQueues::PendingWireframeQueues(),
  )
  world.insert_resource(
    SpecializedWireframePipelineCache::resource(),
    SpecializedWireframePipelineCache::SpecializedWireframePipelineCache(),
  )
  world.insert_resource(
    SpecializedWireframeMeshPipelines::resource(),
    SpecializedWireframeMeshPipelines::SpecializedWireframeMeshPipelines(),
  )
  let wireframe_instances = RenderWireframeInstances::RenderWireframeInstances()
  wireframe_instances.insert(main_entity, 8)
  world.insert_resource(
    RenderWireframeInstances::resource(),
    wireframe_instances,
  )
  let render_wireframe_assets = RenderWireframeAssets::RenderWireframeAssets()
  render_wireframe_assets.insert(
    8,
    RenderWireframeMaterial::from_material(
      WireframeMaterial::new(@color.Color::white(), 1.0F, Triangles),
    ),
  )
  world.insert_resource(
    RenderWireframeAssets::resource(),
    render_wireframe_assets,
  )
  world.insert_resource(
    DirtyWireframeSpecializations::resource(),
    DirtyWireframeSpecializations::DirtyWireframeSpecializations(),
  )
  let render_mesh_instances = RenderMeshInstances::new()
  render_mesh_instances.insert(
    main_entity,
    RenderMeshQueueData::new(33, 9U, true),
  )
  world.insert_resource(RenderMeshInstances::resource(), render_mesh_instances)
  let pipeline_data_cache = WireframeRenderMeshPipelineDataCache::WireframeRenderMeshPipelineDataCache()
  pipeline_data_cache.insert(
    view,
    33,
    wireframe_mesh_pipeline_data_for_render_mesh(
      @render_mesh.RenderMesh::new(vertex_count=3),
      wireframe_phase_test_descriptor(),
      view_key_bits=0UL,
    ),
  )
  world.insert_resource(
    WireframeRenderMeshPipelineDataCache::resource(),
    pipeline_data_cache,
  )
  world.insert_resource(
    Wireframe3dPipeline::resource(),
    Wireframe3dPipeline::new(),
  )
  world.insert_resource(
    @render.pipeline_cache_resource_key,
    @render_resource.PipelineCache::new(),
  )
  let mesh_allocator = @render_mesh.MeshAllocator::new()
  let _ = mesh_allocator.allocate_render_mesh(
    33,
    @render_mesh.RenderMesh::new(vertex_count=3, indexed=true, index_count=3),
    80,
  )
  world.insert_resource(@render_mesh.MeshAllocator::resource(), mesh_allocator)
  world.insert_resource(
    Wireframe3dDrawFunctions::resource(),
    Wireframe3dDrawFunctions::Wireframe3dDrawFunctions(),
  )

  specialize_wireframes_system(world)
  queue_wireframes_system(world)

  let pipeline_cache = world
    .get_resource(SpecializedWireframePipelineCache::resource())
    .unwrap()
  let phases = world.get_resource(Wireframe3dPhases::resource()).unwrap()
  let phase = phases.phase(view).unwrap()
  debug_inspect(
    pipeline_cache.pipeline_id(view, main_entity).map(fn(value) { value.id() }),
    content="Some(0)",
  )
  debug_inspect(phase.len(), content="1")
  let item = phase.items[0]
  debug_inspect(item.main_entity() == main_entity, content="true")
  debug_inspect(item.draw_function().id(), content="0")
  debug_inspect(
    item.batch_set_key().slabs().index_slab_id() is Some(_),
    content="true",
  )
  debug_inspect(item.batch_set_key().mesh_asset_id(), content="None")
  debug_inspect(phase.input_uniform_index(main_entity), content="Some(0)")
}

///|
test "pbr: wireframe view key cache follows pending render camera view bits" {
  let world = @ecs.World::new()
  let view = @core.Entity::new(51, 1)
  let stale_view = @core.Entity::new(52, 1)
  let cache = WireframeViewKeyCache::WireframeViewKeyCache()
  cache.insert(stale_view, 123UL)
  world.insert_resource(WireframeViewKeyCache::resource(), cache)
  render3d_queue_store_pending_frame(
    world,
    wireframe_phase_test_frame_config(),
    [wireframe_phase_test_camera(view, motion_vector_prepass_enabled=true)],
    [],
  )

  prepare_wireframe_view_key_cache_system(world)

  let cache = world.get_resource(WireframeViewKeyCache::resource()).unwrap()
  let view_bits = cache.get(view).unwrap()
  debug_inspect(cache.len(), content="1")
  debug_inspect(cache.get(stale_view), content="None")
  debug_inspect(
    (view_bits & MESH_PIPELINE_KEY_MOTION_VECTOR_PREPASS) != 0UL,
    content="true",
  )
}

///|
test "pbr: extract_wireframe_3d_camera prepares active camera phases" {
  let world = @ecs.World::new()
  let active_camera = world.spawn()
  let inactive_camera = world.spawn()
  let stale_view = @core.Entity::new(12, 1)
  let phases = Wireframe3dPhases::Wireframe3dPhases()
  phases.prepare_for_new_frame(
    stale_view,
    @render_batching.GpuPreprocessingMode::Culling,
  )
  world.insert_resource(Wireframe3dPhases::resource(), phases)
  try! world.set_by_key(active_camera, ecs_key_camera3d, Camera3d::Camera3d())
  try! world.set_by_key(
    active_camera,
    @camera_camera.ecs_key_camera,
    @camera_camera.Camera::Camera(),
  )
  try! world.set_by_key(inactive_camera, ecs_key_camera3d, Camera3d::Camera3d())
  try! world.set_by_key(
    inactive_camera,
    @camera_camera.ecs_key_camera,
    @camera_camera.Camera::Camera().with_is_active(false),
  )

  extract_wireframe_3d_camera_system(world)

  let phases = match world.get_resource(Wireframe3dPhases::resource()) {
    Some(value) => value
    None => abort("missing Wireframe3dPhases")
  }
  debug_inspect(phases.len(), content="1")
  debug_inspect(phases.contains(active_camera), content="true")
  debug_inspect(phases.contains(inactive_camera), content="false")
  debug_inspect(phases.contains(stale_view), content="false")
}

///|
test "pbr: extract_wireframe_render_visible_entities mirrors camera visible Mesh3d pairs" {
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
    render_camera,
    @render.ecs_key_main_entity,
    @render.MainEntity::new(main_camera),
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

  extract_wireframe_render_visible_entities_system(world)

  match
    (try! world.get_by_key(
      render_camera, @render_visibility.ecs_key_render_visible_entities,
    )) {
    Some(render_visible) =>
      match render_visible.get(wireframe_mesh_visibility_class()) {
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
  extract_wireframe_render_visible_entities_system(world)

  match
    (try! world.get_by_key(
      render_camera, @render_visibility.ecs_key_render_visible_entities,
    )) {
    Some(render_visible) =>
      match render_visible.get(wireframe_mesh_visibility_class()) {
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
test "pbr: extract_wireframe_render_visible_entities removes inactive camera component" {
  let world = @ecs.World::new()
  let main_camera = world.spawn()
  let render_camera = world.spawn()
  try! world.set_by_key(main_camera, ecs_key_camera3d, Camera3d::Camera3d())
  try! world.set_by_key(
    main_camera,
    @camera_camera.ecs_key_camera,
    @camera_camera.Camera::Camera().with_is_active(false),
  )
  try! world.set_by_key(
    main_camera,
    @camera_camera.ecs_key_visible_entities,
    @camera_camera.VisibleEntities::VisibleEntities(),
  )
  try! world.set_by_key(
    main_camera,
    @render.ecs_key_render_entity,
    @render.RenderEntity::new(render_camera),
  )
  try! world.set_by_key(
    render_camera,
    @render_visibility.ecs_key_render_visible_entities,
    @render_visibility.RenderVisibleEntities::RenderVisibleEntities(),
  )

  extract_wireframe_render_visible_entities_system(world)

  debug_inspect(
    (try! world.get_by_key(
      render_camera, @render_visibility.ecs_key_render_visible_entities,
    ))
    is None,
    content="true",
  )
}

///|
test "pbr: wireframe wide bind groups keep vertex pull params by mesh asset" {
  let bind_groups = WireframeWideBindGroups::WireframeWideBindGroups()
  let offset = bind_groups.push(13, WireframeVertexPullParams::new(1U, 8U, 3U))
  debug_inspect(offset, content="0")
  debug_inspect(bind_groups.len(), content="1")
  debug_inspect(bind_groups.dynamic_offset(13), content="Some(0)")
  debug_inspect(
    bind_groups.params(0),
    content="Some({ index_offset: 1, vertex_stride_u32s: 8, position_offset_u32s: 3 })",
  )
  bind_groups.clear()
  debug_inspect(bind_groups.len(), content="0")
}

///|
test "pbr: prepare wide wireframe bind groups mirrors Bevy filtering" {
  let mesh_layouts = @mesh.MeshVertexBufferLayouts::MeshVertexBufferLayouts()
  let layout = mesh_layouts.insert(
    @mesh.MeshVertexBufferLayout::new(
      attribute_ids=[@mesh.MeshVertexAttribute::position().id()],
      layout=@mesh.VertexBufferLayout::new(
        array_stride=80,
        step_mode=@mesh.MeshVertexStepMode::Vertex,
        attributes=[
          @mesh.VertexAttribute::new(
            offset=8,
            format=@mesh.MeshVertexFormat::Float32x3,
            shader_location=0,
          ),
        ],
      ),
    ),
  )
  let render_mesh = @render_mesh.RenderMesh::new(
    vertex_count=3,
    indexed=true,
    index_count=3,
    layout~,
  )
  let render_meshes = @render_mesh.RenderMeshAssets::RenderMeshAssets()
  render_meshes.insert(13, render_mesh)
  let mesh_allocator = @render_mesh.MeshAllocator::new()
  ignore(mesh_allocator.allocate_render_mesh(13, render_mesh, 80))
  let render_mesh_instances = RenderMeshInstances::new()
  let first = @render.MainEntity::new(@core.Entity::new(1, 1))
  let duplicate = @render.MainEntity::new(@core.Entity::new(2, 1))
  let thin = @render.MainEntity::new(@core.Entity::new(3, 1))
  render_mesh_instances.insert(first, RenderMeshQueueData::new(13, 0U, true))
  render_mesh_instances.insert(
    duplicate,
    RenderMeshQueueData::new(13, 1U, true),
  )
  render_mesh_instances.insert(thin, RenderMeshQueueData::new(14, 2U, true))
  let render_wireframe_instances = RenderWireframeInstances::RenderWireframeInstances()
  render_wireframe_instances.insert(first, 7)
  render_wireframe_instances.insert(duplicate, 7)
  render_wireframe_instances.insert(thin, 8)
  let render_wireframe_assets = RenderWireframeAssets::RenderWireframeAssets()
  render_wireframe_assets.insert(
    7,
    RenderWireframeMaterial::from_material(
      WireframeMaterial::new(@color.Color::white(), 2.0F, Triangles),
    ),
  )
  render_wireframe_assets.insert(
    8,
    RenderWireframeMaterial::from_material(
      WireframeMaterial::new(@color.Color::white(), 1.0F, Triangles),
    ),
  )
  let bind_groups = WireframeWideBindGroups::WireframeWideBindGroups()

  prepare_wireframe_wide_bind_groups(
    render_mesh_instances, render_meshes, render_wireframe_instances, render_wireframe_assets,
    mesh_allocator, bind_groups,
  )

  debug_inspect(bind_groups.len(), content="1")
  debug_inspect(bind_groups.dynamic_offset(13), content="Some(0)")
  debug_inspect(bind_groups.dynamic_offset(14), content="None")
  let params = bind_groups.params(0).unwrap()
  debug_inspect(params.index_offset(), content="0")
  debug_inspect(params.vertex_stride_u32s(), content="20")
  debug_inspect(params.position_offset_u32s(), content="2")
}

///|
test "pbr: wireframe draw function resource registers thin and wide commands" {
  let draw_functions = Wireframe3dDrawFunctions::Wireframe3dDrawFunctions()
  debug_inspect(draw_functions.len(), content="2")
  debug_inspect(draw_functions.thin().id(), content="0")
  debug_inspect(draw_functions.wide().id(), content="1")
}

///|
test "pbr: wireframe 3d render node mirrors Bevy skip branches" {
  let node = Wireframe3dRenderNode::Wireframe3dRenderNode()
  debug_inspect(node.label(), content="\"wireframe_3d\"")
  let retained_view = @core.Entity::new(1, 1)
  let phases = Wireframe3dPhases::Wireframe3dPhases()
  let missing_phase = Some(
    wireframe_3d_render_node_plan(phases, retained_view, false),
  ) catch {
    error => {
      debug_inspect(
        error is Wireframe3dRenderNodeSkipReason::MissingPhase,
        content="true",
      )
      None
    }
  }
  debug_inspect(missing_phase is None, content="true")
  phases.prepare_for_new_frame(
    retained_view,
    @render_batching.GpuPreprocessingMode::PreprocessingOnly,
  )
  let empty_phase = Some(
    wireframe_3d_render_node_plan(phases, retained_view, false),
  ) catch {
    error => {
      debug_inspect(
        error is Wireframe3dRenderNodeSkipReason::EmptyPhase,
        content="true",
      )
      None
    }
  }
  debug_inspect(empty_phase is None, content="true")
}

///|
test "pbr: wireframe 3d render node plans nonempty phase pass" {
  let retained_view = @core.Entity::new(1, 1)
  let render_entity = @core.Entity::new(2, 1)
  let main_entity = @render.MainEntity::new(@core.Entity::new(3, 1))
  let phases = Wireframe3dPhases::Wireframe3dPhases()
  phases.prepare_for_new_frame(
    retained_view,
    @render_batching.GpuPreprocessingMode::PreprocessingOnly,
  )
  phases.add(
    retained_view,
    Wireframe3dBatchSetKey::new(
      @material.CachedRenderPipelineId::new(3UL),
      7,
      @material.DrawFunctionId::new(0U),
      @render_mesh.MeshSlabs::new(1, index_slab_id=Some(2)),
    ),
    Wireframe3dBinKey::new(13),
    (render_entity, main_entity),
    9U,
    BatchableMesh,
  )

  let plan = wireframe_3d_render_node_plan(phases, retained_view, true)

  debug_inspect(plan.label(), content="\"wireframe_3d\"")
  debug_inspect(plan.retained_view_entity(), content="{ id: 1, generation: 1 }")
  debug_inspect(plan.item_count(), content="1")
  debug_inspect(plan.viewport_enabled(), content="true")
}

///|
test "pbr: wireframe 3d render node command plan classifies planned skipped and failed items" {
  let retained_view = @core.Entity::new(1, 1)
  let render_entity_a = @core.Entity::new(2, 1)
  let render_entity_b = @core.Entity::new(3, 1)
  let render_entity_c = @core.Entity::new(4, 1)
  let main_entity_a = @render.MainEntity::new(@core.Entity::new(10, 1))
  let main_entity_b = @render.MainEntity::new(@core.Entity::new(11, 1))
  let main_entity_c = @render.MainEntity::new(@core.Entity::new(12, 1))
  let draw_functions = Wireframe3dDrawFunctions::Wireframe3dDrawFunctions()
  let phases = Wireframe3dPhases::Wireframe3dPhases()
  phases.prepare_for_new_frame(
    retained_view,
    @render_batching.GpuPreprocessingMode::None,
  )
  phases.add(
    retained_view,
    Wireframe3dBatchSetKey::new(
      @material.CachedRenderPipelineId::new(3UL),
      7,
      draw_functions.thin(),
      @render_mesh.MeshSlabs::new(1, index_slab_id=Some(2)),
    ),
    Wireframe3dBinKey::new(13),
    (render_entity_a, main_entity_a),
    0U,
    BatchableMesh,
  )
  phases.add(
    retained_view,
    Wireframe3dBatchSetKey::new(
      @material.CachedRenderPipelineId::new(4UL),
      7,
      draw_functions.wide(),
      @render_mesh.MeshSlabs::new(1, index_slab_id=Some(2)),
    ),
    Wireframe3dBinKey::new(13),
    (render_entity_b, main_entity_b),
    1U,
    BatchableMesh,
  )
  phases.add(
    retained_view,
    Wireframe3dBatchSetKey::new(
      @material.CachedRenderPipelineId::new(5UL),
      7,
      @material.DrawFunctionId::new(99U),
      @render_mesh.MeshSlabs::new(1, index_slab_id=Some(2)),
    ),
    Wireframe3dBinKey::new(13),
    (render_entity_c, main_entity_c),
    2U,
    BatchableMesh,
  )
  let render_wireframe_instances = RenderWireframeInstances::RenderWireframeInstances()
  render_wireframe_instances.insert(main_entity_a, 7)
  render_wireframe_instances.insert(main_entity_b, 7)
  render_wireframe_instances.insert(main_entity_c, 7)
  let render_wireframe_assets = RenderWireframeAssets::RenderWireframeAssets()
  render_wireframe_assets.insert(
    7,
    RenderWireframeMaterial::from_material(
      WireframeMaterial::new(@color.Color::white(), 2.0F, Triangles),
    ),
  )
  let render_mesh_instances = RenderMeshInstances::new()
  render_mesh_instances.insert(
    main_entity_b,
    RenderMeshQueueData::new(13, 0U, true),
  )
  let render_meshes = @render_mesh.RenderMeshAssets::RenderMeshAssets()
  let render_mesh = @render_mesh.RenderMesh::new(
    vertex_count=8,
    indexed=true,
    index_count=6,
  )
  render_meshes.insert(13, render_mesh)
  let mesh_allocator = @render_mesh.MeshAllocator::new()
  ignore(mesh_allocator.allocate_render_mesh(13, render_mesh, 80))
  let plan = wireframe_3d_render_node_command_plan(
    phases,
    retained_view,
    true,
    draw_functions,
    render_wireframe_instances,
    render_wireframe_assets,
    render_mesh_instances,
    render_meshes,
    mesh_allocator,
    WireframeWideBindGroups::WireframeWideBindGroups(),
  )

  debug_inspect(plan.item_count(), content="3")
  debug_inspect(plan.viewport_enabled(), content="true")
  debug_inspect(plan.command_plan_count(), content="1")
  debug_inspect(plan.command_skip_count(), content="1")
  debug_inspect(plan.command_failure_count(), content="1")
}

///|
test "pbr: wireframe 3d render node is scheduled between main pass and early postprocess" {
  let log : Array[String] = []
  let graph_stage = @render.RenderGraph::schedule()
  let render_sub_app = @app.SubApp::new(@ecs.World::new())
    .set_update_schedule(Some(graph_stage))
    .add_schedule(@render.RenderGraph::base_schedule())
  let render_sub_app = configure_wireframe_render_sub_app(render_sub_app)
    .add_systems(
      graph_stage,
      @app.system(fn(_world : @ecs.World) { log.push("main") }).in_set(
        @core_pipeline.core3d_system_set_main_pass(),
      ),
    )
    .add_systems(
      graph_stage,
      @app.system(fn(_world : @ecs.World) { log.push("wireframe") }).in_set(
        wireframe_render_set_node,
      ),
    )
    .add_systems(
      graph_stage,
      @app.system(fn(_world : @ecs.World) { log.push("early_post") }).in_set(
        @core_pipeline.core3d_system_set_early_post_process(),
      ),
    )

  ignore(render_sub_app.update())

  debug_inspect(log.join(","), content="\"main,wireframe,early_post\"")
}
