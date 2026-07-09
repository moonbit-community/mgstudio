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
fn render3d_main_phase_test_item(
  entity_id : Int,
  phase : Int,
) -> MeshPhaseItem3d {
  let entity = @core.Entity::new(entity_id, 0)
  MeshPhaseItem3d::{
    entity: phase_entity_ref3d_for_main(entity),
    extracted_index: entity_id,
    phase,
    pipeline_id: @material.CachedRenderPipelineId::new(entity_id.to_uint64()),
    distance: Float::from_int(entity_id),
    mesh_asset_id: entity_id,
    slabs: @render_mesh.MeshSlabs::new(entity_id),
    material_bind_group_index: entity_id,
    material_bind_group_slot: 0,
  }
}

///|
test "pbr: main view phases prepare retained views from queued material meshes" {
  let world = @ecs.World::new()
  let view = @core.Entity::new(10, 0)
  let draw_items = [render3d_main_phase_test_item(20, RENDER3D_PHASE_OPAQUE)]

  render3d_prepare_main_view_phase(world, view, draw_items)
  draw_items.push(render3d_main_phase_test_item(21, RENDER3D_PHASE_TRANSPARENT))

  let stored = render3d_main_view_phase_items_or_abort(world, view)
  debug_inspect(stored.length(), content="1")
  debug_inspect(stored[0].entity.main_entity.id, content="20")
  debug_inspect(
    render3d_main_view_phase_item_count_or_abort(world, view),
    content="1",
  )

  render3d_prepare_main_view_phase(world, view, [])
  debug_inspect(
    render3d_main_view_phase_items_or_abort(world, view).length(),
    content="0",
  )
}

///|
test "pbr: main view phases retain only live cameras" {
  let world = @ecs.World::new()
  let live_view = @core.Entity::new(30, 0)
  let stale_view = @core.Entity::new(31, 0)
  render3d_prepare_main_view_phase(world, live_view, [
    render3d_main_phase_test_item(40, RENDER3D_PHASE_OPAQUE),
  ])
  render3d_prepare_main_view_phase(world, stale_view, [
    render3d_main_phase_test_item(41, RENDER3D_PHASE_ALPHA_MASK),
  ])
  let camera = ExtractedCamera3d::{
    entity: phase_entity_ref3d_for_main(live_view),
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
      projection: Projection::Perspective(
        PerspectiveProjection3d::PerspectiveProjection3d(),
      ),
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
      transform: @transform.Transform::identity(),
      previous_transform: @transform.Transform::identity(),
      previous_clip_from_world: None,
      target_id: -1,
      target_size: @math.IVec2::new(640, 480),
      scale_factor: 1.0,
      layers: @camera_render_layers.RenderLayers::RenderLayers(),
      has_no_cpu_culling: false,
      invert_culling: false,
    },
  }

  render3d_retain_live_main_view_phases(world, [camera])

  let phases = match world.get_resource(Render3dMainViewPhases::resource()) {
    Some(value) => value
    None => abort("missing main view phases")
  }
  debug_inspect(phases.phase(live_view) is Some(_), content="true")
  debug_inspect(phases.phase(stale_view) is Some(_), content="false")
}
