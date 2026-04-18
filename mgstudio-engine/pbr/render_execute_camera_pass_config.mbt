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
priv struct Render3dExecuteCameraPassConfig {
  camera_deferred_enabled : Bool
  camera_forward_decal_enabled : Bool
  camera_clustered_decal_enabled : Bool
  effective_exposure : Exposure?
  camera_exposure_value : Float
  distance_fog : DistanceFog
  clear_enabled : Bool
  clear_color : @sprite.Color
  motion_blur_active : Bool
  transmission_blur_taps : Int
  transmission_steps : Int
  transmission_enabled : Bool
  bloom_enabled : Bool
  tonemap_postprocess_enabled : Bool
  effect_stack_postprocess_enabled : Bool
  custom_post_process_enabled : Bool
  tonemapping_stage_enabled : Bool
  fxaa_postprocess_enabled : Bool
  auto_exposure_enabled : Bool
  motion_vector_prepass_enabled : Bool
  fog_enabled : Bool
  scene_pass_kind : Int
  motion_vector_pass_kind : Int
  point_shadow_pass_kind : Int
  point_shadow_near : Float
}

///|
fn render3d_execute_camera_pass_config(
  camera : Camera3dViewPayload,
  camera_deferred_mode : OpaqueRendererMethod,
  deferred_lighting_enabled : Bool,
  prepass_enabled : Bool,
  temporal_aa_enabled : Bool,
  pass_lighting : Render3dLightingState,
) -> Render3dExecuteCameraPassConfig {
  let camera_deferred_enabled = deferred_lighting_enabled &&
    prepass_enabled &&
    (
      camera.deferred_prepass_enabled ||
      camera.camera3d.deferred_config.requires_deferred_prepass ||
      camera_deferred_mode is OpaqueRendererMethod::Deferred
    )
  let camera_msaa_allows_forward_decals = match camera.msaa {
    Some(msaa) => msaa is Msaa::Off
    None => true
  }
  let camera_forward_decal_enabled = render3d_decal_mode_allows_forward(
      camera.camera3d.decal_config.mode,
    ) &&
    camera_msaa_allows_forward_decals &&
    (
      !camera.camera3d.decal_config.requires_depth_prepass ||
      camera.depth_prepass_enabled
    )
  let camera_clustered_decal_enabled = render3d_decal_mode_allows_clustered(
      camera.camera3d.decal_config.mode,
    ) &&
    (
      !camera.camera3d.decal_config.clustered_requires_deferred_prepass ||
      camera_deferred_enabled
    )
  let effective_exposure = camera.exposure
  let camera_exposure_value = match effective_exposure {
    Some(value) => value.exposure()
    None => Exposure::default().exposure()
  }
  let camera_base_fog = match camera.distance_fog {
    Some(value) => value
    None =>
      DistanceFog::new(
        @sprite.Color::new(0.0F, 0.0F, 0.0F, 0.0F),
        FogFalloff3d::linear(0.0F, 0.0F),
      )
  }
  let distance_fog = render3d_camera_distance_fog(
    camera_base_fog,
    camera.camera3d.volumetric_fog,
    camera.camera3d.atmosphere,
    camera.camera3d.atmosphere_settings,
  )
  let (clear_enabled, resolved_clear_color) = camera.camera.clear_color.resolve()
  let clear_color = resolved_clear_color
  let motion_blur_active = if camera.motion_blur is Some(motion_blur) {
    motion_blur.samples > 0 && motion_blur.shutter_angle > 0.0F
  } else {
    false
  }
  let transmission_blur_taps = if camera.screen_space_transmission
    is Some(transmission) &&
    transmission.steps > 0 {
    screen_space_transmission_blur_taps(transmission.quality)
  } else {
    0
  }
  let transmission_steps = if camera.screen_space_transmission
    is Some(transmission) {
    transmission.steps
  } else {
    0
  }
  let transmission_enabled = transmission_blur_taps > 0
  let bloom_enabled = camera.bloom is Some(_)
  let tonemapping_stage_enabled = render3d_tonemapping_stage_enabled(
    camera.tonemapping,
    camera.deband_dither,
    camera.hdr_enabled,
    camera.color_grading,
  )
  let effect_stack_postprocess_enabled = render3d_effect_stack_enabled(
    camera.chromatic_aberration,
    camera.vignette,
  )
  let custom_post_process_enabled = render3d_custom_post_process_enabled(
    camera.custom_post_process3d,
  )
  let fxaa_postprocess_enabled = render3d_fxaa_enabled(camera.fxaa)
  let tonemap_postprocess_enabled = tonemapping_stage_enabled ||
    effect_stack_postprocess_enabled ||
    custom_post_process_enabled ||
    fxaa_postprocess_enabled
  let auto_exposure_enabled = camera.camera3d.auto_exposure is Some(_)
  let motion_vector_prepass_enabled = prepass_enabled &&
    (
      motion_blur_active ||
      camera.motion_vector_prepass_enabled ||
      temporal_aa_enabled ||
      camera.gpu_occlusion_culling_enabled
    )
  let fog_enabled = render3d_distance_fog_enabled(distance_fog)
  let decal_enabled = camera_forward_decal_enabled ||
    camera_clustered_decal_enabled
  let postprocess_enabled = motion_blur_active ||
    bloom_enabled ||
    tonemap_postprocess_enabled ||
    auto_exposure_enabled
  let scene_pass_kind = @pbr_render.render3d_pass_kind_encode(
    @pbr_render.RENDER3D_PASS_KIND_BASE_SCENE,
    postprocess_enabled,
    fog_enabled,
    decal_enabled,
  )
  let motion_vector_pass_kind = @pbr_render.render3d_pass_kind_encode(
    @pbr_render.RENDER3D_PASS_KIND_BASE_MOTION_VECTOR,
    false,
    false,
    false,
  )
  let point_shadow_pass_kind = @pbr_render.render3d_pass_kind_encode(
    @pbr_render.RENDER3D_PASS_KIND_BASE_POINT_SHADOW,
    false,
    false,
    false,
  )
  let point_shadow_near = if pass_lighting.point_shadow_map_near_z > 0.0001F {
    pass_lighting.point_shadow_map_near_z
  } else {
    0.0001F
  }
  Render3dExecuteCameraPassConfig::{
    camera_deferred_enabled,
    camera_forward_decal_enabled,
    camera_clustered_decal_enabled,
    effective_exposure,
    camera_exposure_value,
    distance_fog,
    clear_enabled,
    clear_color,
    motion_blur_active,
    transmission_blur_taps,
    transmission_steps,
    transmission_enabled,
    bloom_enabled,
    tonemap_postprocess_enabled,
    effect_stack_postprocess_enabled,
    custom_post_process_enabled,
    tonemapping_stage_enabled,
    fxaa_postprocess_enabled,
    auto_exposure_enabled,
    motion_vector_prepass_enabled,
    fog_enabled,
    scene_pass_kind,
    motion_vector_pass_kind,
    point_shadow_pass_kind,
    point_shadow_near,
  }
}
