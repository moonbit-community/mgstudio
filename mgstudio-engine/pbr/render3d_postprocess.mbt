// Copyright 2025 International Digital Economy Academy
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
fn render3d_fxaa_enabled(fxaa : Fxaa?) -> Bool {
  match fxaa {
    Some(value) => value.enabled
    None => false
  }
}

///|
fn render3d_tonemapping_stage_enabled(
  tonemapping : Tonemapping?,
  deband_dither : DebandDither?,
  hdr_enabled : Bool,
  color_grading : ColorGrading?,
) -> Bool {
  deband_dither |> ignore
  let color_grading_enabled = color_grading is Some(_)
  if color_grading_enabled {
    return true
  }
  if !hdr_enabled {
    return false
  }
  match tonemapping {
    Some(None) => false
    Some(_) => true
    None => Tonemapping::default() != None
  }
}

///|
fn render3d_effect_stack_enabled(
  chromatic_aberration : ChromaticAberration?,
  vignette : Vignette?,
) -> Bool {
  render3d_chromatic_aberration_enabled(chromatic_aberration) ||
  render3d_vignette_enabled(vignette)
}

///|
fn render3d_custom_post_process_enabled(
  custom_post_process3d : CustomPostProcess3d?,
) -> Bool {
  match custom_post_process3d {
    Some(value) => value.enabled && value.shader_path.trim() != ""
    None => false
  }
}

///|
fn render3d_chromatic_aberration_enabled(
  chromatic_aberration : ChromaticAberration?,
) -> Bool {
  match chromatic_aberration {
    Some(value) => value.intensity > 0.0F && value.max_samples > 0
    None => false
  }
}

///|
fn render3d_vignette_enabled(vignette : Vignette?) -> Bool {
  match vignette {
    Some(value) => value.intensity > 0.0F
    None => false
  }
}

///|
const RENDER3D_TONEMAPPING_LUT_AGX_PATH : String = "textures/tonemapping/AgX-default_contrast.ktx2"

///|
const RENDER3D_TONEMAPPING_LUT_TONY_PATH : String = "textures/tonemapping/tony_mc_mapface.ktx2"

///|
const RENDER3D_TONEMAPPING_LUT_BLENDER_PATH : String = "textures/tonemapping/Blender_-11_12.ktx2"

///|
priv struct Render3dTonemappingLutHandles {
  agx : @asset.Handle[@asset.Image]
  tony : @asset.Handle[@asset.Image]
  blender : @asset.Handle[@asset.Image]
}

///|
fn render3d_tonemapping_lut_handles(
  world : @ecs.World,
) -> Render3dTonemappingLutHandles {
  let internal_assets = render3d_internal_assets_ref_or_abort(world)
  if internal_assets.val.tonemapping_luts is Some(handles) {
    return handles
  }
  let asset_server = render3d_asset_server_from_world_or_abort(world)
  let handles = Render3dTonemappingLutHandles::{
    agx: asset_server.load(RENDER3D_TONEMAPPING_LUT_AGX_PATH),
    tony: asset_server.load(RENDER3D_TONEMAPPING_LUT_TONY_PATH),
    blender: asset_server.load(RENDER3D_TONEMAPPING_LUT_BLENDER_PATH),
  }
  internal_assets.val.tonemapping_luts = Some(handles)
  handles
}

///|
priv struct Render3dAutoExposureCurveGpuData {
  lut : Bytes
  min_log_lum : Float
  max_log_lum : Float
  min_compensation : Float
  max_compensation : Float
}

///|
fn render3d_default_auto_exposure_curve_gpu_data() -> Render3dAutoExposureCurveGpuData {
  Render3dAutoExposureCurveGpuData::{
    lut: Bytes::makei(256, _ => 0),
    min_log_lum: 0.0F,
    max_log_lum: 0.0F,
    min_compensation: 0.0F,
    max_compensation: 0.0F,
  }
}

///|
fn render3d_auto_exposure_curve_gpu_data(
  world : @ecs.World,
  curve_handle : @asset.Handle[AutoExposureCompensationCurve]?,
) -> Render3dAutoExposureCurveGpuData {
  let key : @ecs.ResourceKey[@asset.Assets[AutoExposureCompensationCurve]] = @asset.assets_resource_key()
  guard (try! world.get_resource(key)) is Some(curves) else {
    return render3d_default_auto_exposure_curve_gpu_data()
  }
  let resolved_handle = match curve_handle {
    Some(handle) => handle
    None => @asset.Handle::new(0)
  }
  match curves.get(resolved_handle) {
    Some(curve) =>
      Render3dAutoExposureCurveGpuData::{
        lut: curve.lut,
        min_log_lum: curve.min_log_lum,
        max_log_lum: curve.max_log_lum,
        min_compensation: curve.min_compensation,
        max_compensation: curve.max_compensation,
      }
    None => render3d_default_auto_exposure_curve_gpu_data()
  }
}

///|
fn render3d_apply_camera_auto_exposure(
  world : @ecs.World,
  camera_entity : @core.Entity,
  auto_exposure : AutoExposure,
  color_grading : @post_process.ColorGrading?,
  scene_texture_id : Int,
  view_width_logical : Int,
  view_height_logical : Int,
  delta_time : Float,
) -> Unit {
  if scene_texture_id < 0 || view_width_logical <= 0 || view_height_logical <= 0 {
    return
  }
  let curve = render3d_auto_exposure_curve_gpu_data(
    world,
    auto_exposure.compensation_curve,
  )
  let color_grading_uniform = @render.host_color_grading_from_post_process(
    color_grading,
  )
  @render.host_gpu_apply_auto_exposure(
    view_key_hi=camera_entity.id,
    view_key_lo=camera_entity.generation,
    scene_texture_id~,
    min_ev100=auto_exposure.min_ev100,
    max_ev100=auto_exposure.max_ev100,
    low_percent=auto_exposure.low_percent,
    high_percent=auto_exposure.high_percent,
    speed_brighten=auto_exposure.speed_brighten,
    speed_darken=auto_exposure.speed_darken,
    exponential_transition_distance=auto_exposure.exponential_transition_distance,
    delta_time~,
    color_grading=color_grading_uniform,
    metering_mask_texture_id=match auto_exposure.metering_mask {
      Some(mask) => mask.id()
      None => -1
    },
    compensation_curve_lut=curve.lut,
    compensation_curve_min_log_lum=curve.min_log_lum,
    compensation_curve_max_log_lum=curve.max_log_lum,
    compensation_curve_min_compensation=curve.min_compensation,
    compensation_curve_max_compensation=curve.max_compensation,
    view_width=view_width_logical,
    view_height=view_height_logical,
  )
}

///|
fn render3d_bloom_clamp_unit(value : Float) -> Float {
  if value < 0.0F {
    0.0F
  } else if value > 1.0F {
    1.0F
  } else {
    value
  }
}

///|
fn render3d_bloom_clamp_non_negative(value : Float) -> Float {
  if value < 0.0F {
    0.0F
  } else {
    value
  }
}

///|
fn render3d_bloom_safe_max_mip_dimension(value : Int) -> Int {
  if value < 4 {
    4
  } else {
    value
  }
}

///|
fn render3d_bloom_safe_scale_axis(value : Float) -> Float {
  if value < 0.0F {
    0.0F
  } else {
    value
  }
}

///|
fn render3d_bloom_sanitize(bloom : Bloom) -> Bloom {
  let prefilter = BloomPrefilter::new(
    render3d_bloom_clamp_non_negative(bloom.prefilter.threshold),
    render3d_bloom_clamp_unit(bloom.prefilter.threshold_softness),
  )
  Bloom::new(render3d_bloom_clamp_non_negative(bloom.intensity))
  .with_low_frequency_boost(
    render3d_bloom_clamp_unit(bloom.low_frequency_boost),
  )
  .with_low_frequency_boost_curvature(
    render3d_bloom_clamp_unit(bloom.low_frequency_boost_curvature),
  )
  .with_high_pass_frequency(
    render3d_bloom_clamp_unit(bloom.high_pass_frequency),
  )
  .with_prefilter_settings(prefilter)
  .with_composite_mode(bloom.composite_mode)
  .with_max_mip_dimension(
    render3d_bloom_safe_max_mip_dimension(bloom.max_mip_dimension),
  )
  .with_scale(
    @math.Vec2::new(
      render3d_bloom_safe_scale_axis(bloom.scale.x),
      render3d_bloom_safe_scale_axis(bloom.scale.y),
    ),
  )
}

///|
fn render3d_tonemapping_mode_to_int(mode : Tonemapping) -> Int {
  match mode {
    None => 0
    Reinhard => 1
    ReinhardLuminance => 2
    AcesFitted => 3
    AgX => 4
    SomewhatBoringDisplayTransform => 5
    TonyMcMapface => 6
    BlenderFilmic => 7
  }
}

///|
fn render3d_fxaa_sensitivity_mode_int(sensitivity : FxaaSensitivity) -> Int {
  match sensitivity {
    Low => 0
    Medium => 1
    High => 2
    Ultra => 3
    Extreme => 4
  }
}

///|
fn render3d_fxaa_postprocess_values(fxaa : Fxaa?) -> (Int, Int, Int) {
  match fxaa {
    Some(value) =>
      (
        if value.enabled {
          1
        } else {
          0
        },
        render3d_fxaa_sensitivity_mode_int(value.edge_threshold),
        render3d_fxaa_sensitivity_mode_int(value.edge_threshold_min),
      )
    None =>
      (
        0,
        render3d_fxaa_sensitivity_mode_int(FxaaSensitivity::default()),
        render3d_fxaa_sensitivity_mode_int(FxaaSensitivity::default()),
      )
  }
}

///|
fn render3d_chromatic_aberration_postprocess_values(
  chromatic_aberration : ChromaticAberration?,
) -> (Float, Int) {
  match chromatic_aberration {
    Some(value) =>
      (
        if value.intensity < 0.0F {
          0.0F
        } else {
          value.intensity
        },
        if value.max_samples <= 0 {
          1
        } else {
          value.max_samples
        },
      )
    None => {
      let defaults = ChromaticAberration::default()
      (0.0F, defaults.max_samples)
    }
  }
}

///|
fn render3d_vignette_postprocess_values(
  vignette : Vignette?,
) -> (
  Float,
  Float,
  Float,
  Float,
  Float,
  Float,
  Float,
  Float,
  Float,
  Float,
  Float,
) {
  match vignette {
    Some(value) => {
      let safe_edge_compensation = if value.edge_compensation < 0.0F {
        0.0F
      } else if value.edge_compensation > 1.0F {
        1.0F
      } else {
        value.edge_compensation
      }
      (
        if value.intensity < 0.0F {
          0.0F
        } else {
          value.intensity
        },
        if value.radius < 0.0F {
          0.0F
        } else {
          value.radius
        },
        if value.smoothness <= 0.01F {
          0.01F
        } else {
          value.smoothness
        },
        if value.roundness <= 0.01F {
          0.01F
        } else {
          value.roundness
        },
        value.center.x,
        value.center.y,
        safe_edge_compensation,
        value.color.r,
        value.color.g,
        value.color.b,
        value.color.a,
      )
    }
    None => {
      let defaults = Vignette::default()
      (
        0.0F,
        defaults.radius,
        defaults.smoothness,
        defaults.roundness,
        defaults.center.x,
        defaults.center.y,
        defaults.edge_compensation,
        defaults.color.r,
        defaults.color.g,
        defaults.color.b,
        defaults.color.a,
      )
    }
  }
}

///|
fn render3d_postprocess_stage_target(
  source_texture_id : Int,
  scene_texture_id : Int,
  ping_texture_id : Int,
  camera_target_id : Int,
  stage_index : Int,
  stage_count : Int,
) -> Int {
  if stage_index >= stage_count - 1 {
    camera_target_id
  } else if source_texture_id == ping_texture_id {
    scene_texture_id
  } else {
    ping_texture_id
  }
}

///|
fn render3d_draw_camera_effect_stack_stage(
  scene_texture_id : Int,
  chromatic_aberration : ChromaticAberration?,
  vignette : Vignette?,
  view_width_logical : Int,
  view_height_logical : Int,
) -> Unit {
  if !render3d_effect_stack_enabled(chromatic_aberration, vignette) {
    return
  }
  let (chromatic_aberration_intensity, chromatic_aberration_max_samples) = render3d_chromatic_aberration_postprocess_values(
    chromatic_aberration,
  )
  let (
    vignette_intensity,
    vignette_radius,
    vignette_smoothness,
    vignette_roundness,
    vignette_center_x,
    vignette_center_y,
    vignette_edge_compensation,
    vignette_color_r,
    vignette_color_g,
    vignette_color_b,
    vignette_color_a,
  ) = render3d_vignette_postprocess_values(vignette)
  @render.host_gpu_draw_effect_stack(
    scene_texture_id~,
    chromatic_aberration_intensity~,
    chromatic_aberration_max_samples~,
    vignette_intensity~,
    vignette_radius~,
    vignette_smoothness~,
    vignette_roundness~,
    vignette_center_x~,
    vignette_center_y~,
    vignette_edge_compensation~,
    vignette_color_r~,
    vignette_color_g~,
    vignette_color_b~,
    vignette_color_a~,
    view_width=view_width_logical,
    view_height=view_height_logical,
  )
}

///|
fn render3d_draw_camera_custom_post_process_stage(
  scene_texture_id : Int,
  custom_post_process3d : CustomPostProcess3d?,
  view_width_logical : Int,
  view_height_logical : Int,
) -> Unit {
  if !render3d_custom_post_process_enabled(custom_post_process3d) {
    return
  }
  guard custom_post_process3d is Some(custom_post_process) else { return }
  @render.host_gpu_draw_custom_postprocess3d(
    scene_texture_id~,
    shader_path=custom_post_process.shader_path.trim().to_string(),
    fragment_entry=if custom_post_process.fragment_entry.trim().to_string() ==
      "" {
      "fragment_main"
    } else {
      custom_post_process.fragment_entry.trim().to_string()
    },
    uniform_x=custom_post_process.uniform_x,
    uniform_y=custom_post_process.uniform_y,
    uniform_z=custom_post_process.uniform_z,
    uniform_w=custom_post_process.uniform_w,
    view_width=view_width_logical,
    view_height=view_height_logical,
  )
}

///|
fn render3d_draw_camera_tonemapping_stage(
  world : @ecs.World,
  scene_texture_id : Int,
  exposure : Exposure?,
  tonemapping : Tonemapping?,
  deband_dither : DebandDither?,
  color_grading : ColorGrading?,
  hdr_enabled : Bool,
  view_width_logical : Int,
  view_height_logical : Int,
) -> Unit {
  exposure |> ignore
  if !render3d_tonemapping_stage_enabled(
      tonemapping, deband_dither, hdr_enabled, color_grading,
    ) {
    return
  }
  let exposure_value = match exposure {
    Some(value) => value.exposure()
    None => Exposure::default().exposure()
  }
  let luts = render3d_tonemapping_lut_handles(world)
  let color_grading_uniform = @render.host_color_grading_from_post_process(
    color_grading,
  )
  @render.host_gpu_draw_tonemapping3d(
    scene_texture_id~,
    exposure=exposure_value,
    tonemapping_mode=match tonemapping {
      Some(mode) => render3d_tonemapping_mode_to_int(mode)
      None => 0
    },
    deband_dither_enabled=match deband_dither {
      Some(Enabled) => 1
      _ => 0
    },
    view_width=view_width_logical,
    view_height=view_height_logical,
    agx_lut_texture_id=luts.agx.id(),
    tony_lut_texture_id=luts.tony.id(),
    blender_lut_texture_id=luts.blender.id(),
    color_grading=color_grading_uniform,
  )
}

///|
fn render3d_draw_camera_fxaa_stage(
  scene_texture_id : Int,
  fxaa : Fxaa?,
  view_width_logical : Int,
  view_height_logical : Int,
) -> Unit {
  let (fxaa_enabled, fxaa_edge_threshold_mode, fxaa_edge_threshold_min_mode) = render3d_fxaa_postprocess_values(
    fxaa,
  )
  if fxaa_enabled == 0 {
    return
  }
  @render.host_gpu_draw_fxaa(
    scene_texture_id~,
    fxaa_enabled~,
    fxaa_edge_threshold_mode~,
    fxaa_edge_threshold_min_mode~,
    view_width=view_width_logical,
    view_height=view_height_logical,
  )
}

///|
fn render3d_draw_camera_bloom_stage(
  scene_texture_id : Int,
  bloom : Bloom,
  view_width_logical : Int,
  view_height_logical : Int,
) -> Unit {
  if scene_texture_id < 0 || view_width_logical <= 0 || view_height_logical <= 0 {
    return
  }
  let settings = render3d_bloom_sanitize(bloom)
  @render.host_gpu_apply_bloom(
    scene_texture_id~,
    intensity=settings.intensity,
    low_frequency_boost=settings.low_frequency_boost,
    low_frequency_boost_curvature=settings.low_frequency_boost_curvature,
    high_pass_frequency=settings.high_pass_frequency,
    threshold=settings.prefilter.threshold,
    threshold_softness=settings.prefilter.threshold_softness,
    composite_mode=match settings.composite_mode {
      EnergyConserving => 0
      Additive => 1
    },
    max_mip_dimension=settings.max_mip_dimension,
    scale_x=settings.scale.x,
    scale_y=settings.scale.y,
    view_width=view_width_logical,
    view_height=view_height_logical,
  )
}
