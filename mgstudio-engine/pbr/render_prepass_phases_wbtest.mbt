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
extend Render3dAlphaMaskPrepassPhases with @app.Resource::{resource}

///|
extend Render3dOpaqueDeferredPhases with @app.Resource::{resource}

///|
fn render3d_prepass_phase_test_camera(
  entity_id : Int,
  depth_prepass_enabled? : Bool = false,
  normal_prepass_enabled? : Bool = false,
  motion_vector_prepass_enabled? : Bool = false,
  deferred_prepass_enabled? : Bool = false,
  no_indirect_drawing? : Bool = false,
  msaa_samples? : Int = 4,
  active? : Bool = true,
) -> ExtractedCamera3d {
  {
    entity: phase_entity_ref3d_for_main(@core.Entity::new(entity_id, 0)),
    payload: {
      decal_config: None,
      deferred_config: None,
      distance_fog: None,
      auto_exposure: None,
      volumetric_fog: None,
      atmosphere: None,
      atmosphere_settings: None,
      camera: @camera_camera.Camera::Camera().with_is_active(active),
      depth_texture_usages: Camera3dDepthTextureUsage(),
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
      depth_prepass_enabled,
      normal_prepass_enabled,
      deferred_prepass_enabled,
      no_indirect_drawing,
      gpu_occlusion_culling_enabled: false,
      hdr_enabled: false,
      fxaa: None,
      temporal_jitter: None,
      temporal_anti_aliasing: None,
      shadow_filtering_method: None,
      motion_vector_prepass_enabled,
      msaa: Some(Msaa::from_samples(msaa_samples)),
      transform: @transform.Transform::identity(),
      previous_transform: @transform.Transform::identity(),
      previous_clip_from_world: None,
      target_id: 0,
      target_size: @math.IVec2::new(1280, 720),
      scale_factor: 1.0F,
      layers: RenderLayers(),
      invert_culling: false,
    },
  }
}

///|
fn render3d_prepass_phase_test_presence(
  world : @ecs.World,
  view : @render_view.RetainedViewEntity,
) -> (Bool, Bool, Bool, Bool) {
  let opaque_prepass = world
    .get_resource(Render3dOpaquePrepassPhases::resource())
    .unwrap()
  let alpha_mask_prepass = world
    .get_resource(Render3dAlphaMaskPrepassPhases::resource())
    .unwrap()
  let opaque_deferred = world
    .get_resource(Render3dOpaqueDeferredPhases::resource())
    .unwrap()
  let alpha_mask_deferred = world
    .get_resource(Render3dAlphaMaskDeferredPhases::resource())
    .unwrap()
  (
    opaque_prepass.phases.contains(view),
    alpha_mask_prepass.phases.contains(view),
    opaque_deferred.phases.contains(view),
    alpha_mask_deferred.phases.contains(view),
  )
}

///|
fn render3d_prepass_phase_test_world() -> @ecs.World {
  let world = @ecs.World::new()
  world.insert_resource(
    @render_batching.GpuPreprocessingSupport::resource(),
    @render_batching.GpuPreprocessingSupport::with_max_supported_mode(Culling),
  )
  world
}

///|
test "pbr prepass phases: extraction creates only component-selected phases" {
  let world = render3d_prepass_phase_test_world()
  let prepass_view = @render_view.RetainedViewEntity::new(
    @core.Entity::new(10, 0),
  )
  let deferred_view = @render_view.RetainedViewEntity::new(
    @core.Entity::new(11, 0),
  )
  render3d_extract_camera_prepass_phases(world, [
    render3d_prepass_phase_test_camera(10, normal_prepass_enabled=true),
    render3d_prepass_phase_test_camera(11, deferred_prepass_enabled=true),
  ])

  debug_inspect(
    render3d_prepass_phase_test_presence(world, prepass_view),
    content="(true, true, false, false)",
  )
  debug_inspect(
    render3d_prepass_phase_test_presence(world, deferred_view),
    content="(false, false, true, true)",
  )
}

///|
test "pbr prepass phases: extraction removes disabled and inactive views" {
  let world = render3d_prepass_phase_test_world()
  let live_view = @render_view.RetainedViewEntity::new(@core.Entity::new(20, 0))
  let stale_view = @render_view.RetainedViewEntity::new(
    @core.Entity::new(21, 0),
  )
  render3d_extract_camera_prepass_phases(world, [
    render3d_prepass_phase_test_camera(
      20,
      depth_prepass_enabled=true,
      deferred_prepass_enabled=true,
    ),
    render3d_prepass_phase_test_camera(
      21,
      motion_vector_prepass_enabled=true,
      deferred_prepass_enabled=true,
    ),
  ])
  debug_inspect(
    render3d_prepass_phase_test_presence(world, live_view),
    content="(true, true, true, true)",
  )

  render3d_extract_camera_prepass_phases(world, [
    render3d_prepass_phase_test_camera(20),
    render3d_prepass_phase_test_camera(
      21,
      depth_prepass_enabled=true,
      deferred_prepass_enabled=true,
      active=false,
    ),
  ])
  debug_inspect(
    render3d_prepass_phase_test_presence(world, live_view),
    content="(false, false, false, false)",
  )
  debug_inspect(
    render3d_prepass_phase_test_presence(world, stale_view),
    content="(false, false, false, false)",
  )
}

///|
test "pbr prepass phases: extraction selects Bevy GPU preprocessing mode" {
  let world = render3d_prepass_phase_test_world()
  let indirect_view = @render_view.RetainedViewEntity::new(
    @core.Entity::new(30, 0),
  )
  let direct_view = @render_view.RetainedViewEntity::new(
    @core.Entity::new(31, 0),
  )
  render3d_extract_camera_prepass_phases(world, [
    render3d_prepass_phase_test_camera(30, depth_prepass_enabled=true),
    render3d_prepass_phase_test_camera(
      31,
      depth_prepass_enabled=true,
      no_indirect_drawing=true,
    ),
  ])
  let phases = world
    .get_resource(Render3dOpaquePrepassPhases::resource())
    .unwrap()
  debug_inspect(
    phases.phases
    .view(indirect_view)
    .map(fn(view) { view.gpu_preprocessing_mode }),
    content="Some(Culling)",
  )
  debug_inspect(
    phases.phases
    .view(direct_view)
    .map(fn(view) { view.gpu_preprocessing_mode }),
    content="Some(PreprocessingOnly)",
  )
}

///|
test "pbr prepass specialization: view key contains only Bevy prepass bits" {
  let camera = render3d_prepass_phase_test_camera(
    40,
    depth_prepass_enabled=true,
    normal_prepass_enabled=true,
    deferred_prepass_enabled=true,
    msaa_samples=8,
  )
  let expected = mesh_pipeline_key_msaa_bits(8) |
    MESH_PIPELINE_KEY_DEPTH_PREPASS |
    MESH_PIPELINE_KEY_NORMAL_PREPASS
  inspect(render3d_prepass_view_key_bits(camera.payload), content="\{expected}")
  inspect(
    render3d_prepass_view_key_bits(camera.payload) &
    MESH_PIPELINE_KEY_DEFERRED_PREPASS,
    content="0",
  )
}

///|
test "pbr prepass specialization: changed view keys dirty only changed views" {
  let world = render3d_prepass_phase_test_world()
  ensure_render3d_prepass_specialization_resources(world)
  world.insert_resource(
    @render_visibility.DirtySpecializations::resource(),
    DirtySpecializations(),
  )
  let retained_view = @render_view.RetainedViewEntity::new(
    @core.Entity::new(41, 0),
  )
  let initial = render3d_prepass_phase_test_camera(
    41,
    depth_prepass_enabled=true,
  )
  render3d_check_prepass_views_need_specialization(world, [initial])
  let dirty = world
    .get_resource(@render_visibility.DirtySpecializations::resource())
    .unwrap()
  debug_inspect(
    dirty.must_wipe_specializations_for_view(retained_view),
    content="true",
  )
  dirty.clear()
  render3d_check_prepass_views_need_specialization(world, [initial])
  inspect(dirty.views_len(), content="0")
  render3d_check_prepass_views_need_specialization(world, [
    render3d_prepass_phase_test_camera(41, motion_vector_prepass_enabled=true),
  ])
  debug_inspect(
    dirty.must_wipe_specializations_for_view(retained_view),
    content="true",
  )
}

///|
test "pbr prepass specialization: cache retains live views and full entry data" {
  let cache = SpecializedPrepassMaterialPipelineCache::new()
  let live_view = @render_view.RetainedViewEntity::new(@core.Entity::new(42, 0))
  let stale_view = @render_view.RetainedViewEntity::new(
    @core.Entity::new(43, 0),
  )
  let entity = @core.Entity::new(44, 0)
  cache
  .view_or_insert(live_view)
  .insert(
    entity,
    7,
    @material.CachedRenderPipelineId::new(71UL),
    @material.DrawFunctionId::new(72U),
  )
  cache
  .view_or_insert(stale_view)
  .insert(
    entity,
    8,
    @material.CachedRenderPipelineId::new(81UL),
    @material.DrawFunctionId::new(82U),
  )
  let live_views : @hashset.HashSet[@render_view.RetainedViewEntity] = HashSet([])
  live_views.add(live_view)
  cache.retain_live_views(live_views)
  let entry = cache.get(live_view).unwrap().get(entity).unwrap()
  inspect(entry.tick, content="7")
  inspect(entry.pipeline_id.id(), content="71")
  inspect(entry.draw_function.id(), content="72")
  debug_inspect(cache.get(stale_view) is None, content="true")
}

///|
test "pbr prepass queue: retained phase replaces entities and refreshes payload indices" {
  let phase = Render3dRetainedMeshPhaseView::{
    items: [],
    gpu_preprocessing_mode: Culling,
    phase_types: Map([]),
  }
  let entity = phase_entity_ref3d(
    @core.Entity::new(50, 0),
    @core.Entity::new(60, 0),
  )
  fn item(
    entity : PhaseEntityRef3d,
    extracted_index : Int,
    pipeline_id : UInt64,
  ) -> MeshPhaseItem3d {
    {
      entity,
      extracted_index,
      current_uniform_index: 3U,
      phase: RENDER3D_PHASE_OPAQUE,
      draw_function: @material.DrawFunctionId::new(4U),
      pipeline_id: @material.CachedRenderPipelineId::new(pipeline_id),
      distance: 0.0F,
      mesh_asset_id: 5,
      slabs: @render_mesh.MeshSlabs::new(6),
      material_bind_group_index: -1,
      material_bind_group_slot: -1,
    }
  }
  phase.add(item(entity, 0, 7UL), MultidrawableMesh)
  phase.add(item(entity, 1, 8UL), BatchableMesh)
  inspect(phase.items.length(), content="1")
  inspect(phase.items[0].pipeline_id.id(), content="8")
  let indices : Map[UInt64, Int] = Map([])
  indices.set(entity.main_entity.to_bits(), 9)
  phase.refresh_extracted_indices(indices)
  inspect(phase.items[0].extracted_index, content="9")
  debug_inspect(
    phase.phase_types.get(entity.main_entity.to_bits()) is Some(BatchableMesh),
    content="true",
  )
  phase.remove(entity.main_entity)
  inspect(phase.items.length(), content="0")

  let direct_phase = Render3dRetainedMeshPhaseView::{
    items: [],
    gpu_preprocessing_mode: PreprocessingOnly,
    phase_types: Map([]),
  }
  direct_phase.add(item(entity, 0, 9UL), MultidrawableMesh)
  debug_inspect(
    direct_phase.phase_types.get(entity.main_entity.to_bits())
    is Some(BatchableMesh),
    content="true",
  )
}
