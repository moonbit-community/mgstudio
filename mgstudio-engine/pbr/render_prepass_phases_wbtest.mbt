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
fn render3d_prepass_phase_test_camera(
  entity_id : Int,
  depth_prepass_enabled? : Bool = false,
  normal_prepass_enabled? : Bool = false,
  motion_vector_prepass_enabled? : Bool = false,
  deferred_prepass_enabled? : Bool = false,
  no_indirect_drawing? : Bool = false,
  active? : Bool = true,
) -> ExtractedCamera3d {
  ExtractedCamera3d::{
    entity: phase_entity_ref3d_for_main(@core.Entity::new(entity_id, 0)),
    payload: Camera3dViewPayload::{
      decal_config: None,
      deferred_config: None,
      distance_fog: None,
      auto_exposure: None,
      volumetric_fog: None,
      atmosphere: None,
      atmosphere_settings: None,
      camera: @camera_camera.Camera::Camera().with_is_active(active),
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
      msaa: None,
      transform: @transform.Transform::identity(),
      previous_transform: @transform.Transform::identity(),
      previous_clip_from_world: None,
      target_id: 0,
      target_size: @math.IVec2::new(1280, 720),
      scale_factor: 1.0F,
      layers: @camera_render_layers.RenderLayers::RenderLayers(),
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
    @render_batching.GpuPreprocessingSupport::with_max_supported_mode(
      @render_batching.GpuPreprocessingMode::Culling,
    ),
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
    phases.phases.gpu_preprocessing_mode(indirect_view),
    content="Some(Culling)",
  )
  debug_inspect(
    phases.phases.gpu_preprocessing_mode(direct_view),
    content="Some(PreprocessingOnly)",
  )
}
