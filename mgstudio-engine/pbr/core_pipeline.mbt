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
pub(all) enum DecalRenderMode3d {
  Disabled
  ForwardOnly
  ClusteredOnly
  ForwardAndClustered
} derive(Eq, Debug, ToJson, FromJson)

///|
pub fn DecalRenderMode3d::default() -> DecalRenderMode3d {
  DecalRenderMode3d::ForwardAndClustered
}

///|
pub struct CameraDecalConfig3d {
  mode : DecalRenderMode3d
  requires_depth_prepass : Bool
  clustered_requires_deferred_prepass : Bool
} derive(ToJson, FromJson)

///|
pub fn CameraDecalConfig3d::default() -> CameraDecalConfig3d {
  CameraDecalConfig3d::{
    mode: DecalRenderMode3d::ForwardAndClustered,
    requires_depth_prepass: true,
    clustered_requires_deferred_prepass: false,
  }
}

///|
pub fn CameraDecalConfig3d::with_mode(
  self : CameraDecalConfig3d,
  mode : DecalRenderMode3d,
) -> CameraDecalConfig3d {
  CameraDecalConfig3d::{ ..self, mode, }
}

///|
pub fn CameraDecalConfig3d::with_requires_depth_prepass(
  self : CameraDecalConfig3d,
  requires_depth_prepass : Bool,
) -> CameraDecalConfig3d {
  CameraDecalConfig3d::{ ..self, requires_depth_prepass, }
}

///|
pub fn CameraDecalConfig3d::with_clustered_requires_deferred_prepass(
  self : CameraDecalConfig3d,
  clustered_requires_deferred_prepass : Bool,
) -> CameraDecalConfig3d {
  CameraDecalConfig3d::{ ..self, clustered_requires_deferred_prepass, }
}

///|
pub(all) enum CameraDeferredMode3d {
  Auto
  Forward
  Deferred
} derive(Eq, Debug, ToJson, FromJson)

///|
pub fn CameraDeferredMode3d::default() -> CameraDeferredMode3d {
  CameraDeferredMode3d::Auto
}

///|
pub struct CameraDeferredConfig3d {
  mode : CameraDeferredMode3d
  requires_deferred_prepass : Bool
} derive(ToJson, FromJson)

///|
pub fn CameraDeferredConfig3d::default() -> CameraDeferredConfig3d {
  CameraDeferredConfig3d::{
    mode: CameraDeferredMode3d::Auto,
    requires_deferred_prepass: false,
  }
}

///|
pub fn CameraDeferredConfig3d::with_mode(
  self : CameraDeferredConfig3d,
  mode : CameraDeferredMode3d,
) -> CameraDeferredConfig3d {
  CameraDeferredConfig3d::{ ..self, mode, }
}

///|
pub fn CameraDeferredConfig3d::with_requires_deferred_prepass(
  self : CameraDeferredConfig3d,
  requires_deferred_prepass : Bool,
) -> CameraDeferredConfig3d {
  CameraDeferredConfig3d::{ ..self, requires_deferred_prepass, }
}

///|
/// API-parity data model aligned with Bevy's `AutoExposure` camera component.
pub struct AutoExposure {
  min_ev100 : Float
  max_ev100 : Float
  low_percent : Float
  high_percent : Float
  speed_brighten : Float
  speed_darken : Float
  exponential_transition_distance : Float
  compensation_curve : @asset.Handle[AutoExposureCompensationCurve]?
  metering_mask : @asset.Handle[@asset.Image]?
} derive(ToJson, FromJson)

///|
pub fn AutoExposure::default() -> AutoExposure {
  AutoExposure::{
    min_ev100: -8.0F,
    max_ev100: 8.0F,
    low_percent: 0.10F,
    high_percent: 0.90F,
    speed_brighten: 3.0F,
    speed_darken: 1.0F,
    exponential_transition_distance: 1.5F,
    compensation_curve: None,
    metering_mask: None,
  }
}

///|
pub fn AutoExposure::new(min_ev100 : Float, max_ev100 : Float) -> AutoExposure {
  AutoExposure::default().with_range(min_ev100, max_ev100)
}

///|
pub fn AutoExposure::with_range(
  self : AutoExposure,
  min_ev100 : Float,
  max_ev100 : Float,
) -> AutoExposure {
  let safe_min = if min_ev100 < max_ev100 { min_ev100 } else { max_ev100 }
  let safe_max = if max_ev100 > safe_min { max_ev100 } else { safe_min + 0.01F }
  AutoExposure::{ ..self, min_ev100: safe_min, max_ev100: safe_max }
}

///|
pub fn AutoExposure::with_filter(
  self : AutoExposure,
  low_percent : Float,
  high_percent : Float,
) -> AutoExposure {
  let safe_low = if low_percent < 0.0F {
    0.0F
  } else if low_percent > 1.0F {
    1.0F
  } else {
    low_percent
  }
  let mut safe_high = if high_percent < 0.0F {
    0.0F
  } else if high_percent > 1.0F {
    1.0F
  } else {
    high_percent
  }
  if safe_high < safe_low {
    safe_high = safe_low
  }
  AutoExposure::{ ..self, low_percent: safe_low, high_percent: safe_high }
}

///|
pub fn AutoExposure::with_speed_brighten(
  self : AutoExposure,
  speed_brighten : Float,
) -> AutoExposure {
  AutoExposure::{
    ..self,
    speed_brighten: if speed_brighten < 0.0F {
      0.0F
    } else {
      speed_brighten
    },
  }
}

///|
pub fn AutoExposure::with_speed_darken(
  self : AutoExposure,
  speed_darken : Float,
) -> AutoExposure {
  AutoExposure::{
    ..self,
    speed_darken: if speed_darken < 0.0F {
      0.0F
    } else {
      speed_darken
    },
  }
}

///|
pub fn AutoExposure::with_exponential_transition_distance(
  self : AutoExposure,
  exponential_transition_distance : Float,
) -> AutoExposure {
  AutoExposure::{
    ..self,
    exponential_transition_distance: if exponential_transition_distance <= 0.0F {
      0.0001F
    } else {
      exponential_transition_distance
    },
  }
}

///|
pub fn AutoExposure::with_compensation_curve(
  self : AutoExposure,
  compensation_curve : @asset.Handle[AutoExposureCompensationCurve]?,
) -> AutoExposure {
  AutoExposure::{ ..self, compensation_curve, }
}

///|
pub fn AutoExposure::with_metering_mask(
  self : AutoExposure,
  metering_mask : @asset.Handle[@asset.Image]?,
) -> AutoExposure {
  AutoExposure::{ ..self, metering_mask, }
}

///|
pub(all) enum DepthOfFieldMode {
  Bokeh
  Gaussian
} derive(Eq, Debug, ToJson, FromJson)

///|
pub fn DepthOfFieldMode::default() -> DepthOfFieldMode {
  DepthOfFieldMode::Gaussian
}

///|
/// API-parity data model aligned with Bevy's `DepthOfField` camera component.
pub(all) struct DepthOfField {
  mut mode : DepthOfFieldMode
  mut focal_distance : Float
  mut sensor_height : Float
  mut aperture_f_stops : Float
  mut max_circle_of_confusion_diameter : Float
  mut max_depth : Float
} derive(ToJson, FromJson)

///|
pub fn DepthOfField::default() -> DepthOfField {
  DepthOfField::{
    mode: DepthOfFieldMode::default(),
    focal_distance: 10.0F,
    sensor_height: PhysicalCameraParameters::default().sensor_height,
    aperture_f_stops: 4.0F,
    max_circle_of_confusion_diameter: 64.0F,
    max_depth: @float.infinity,
  }
}

///|
pub fn DepthOfField::from_physical_camera(
  camera : PhysicalCameraParameters,
) -> DepthOfField {
  let depth_of_field = DepthOfField::default()
  depth_of_field.sensor_height = camera.sensor_height
  depth_of_field.aperture_f_stops = camera.aperture_f_stops
  depth_of_field
}

///|
/// Camera component aligned with Bevy's `Camera3d`.
///
/// This stores feature toggles and per-camera overrides that influence how the
/// current renderer approximates deferred/decal/volumetric/post-process APIs.
pub struct Camera3d {
  decal_config : CameraDecalConfig3d
  deferred_config : CameraDeferredConfig3d
  distance_fog : DistanceFog?
  volumetric_fog : VolumetricFog?
  atmosphere : Atmosphere?
  atmosphere_settings : AtmosphereSettings?
  auto_exposure : AutoExposure?
  depth_of_field : DepthOfField?
} derive(ToJson, FromJson)

///|
pub fn Camera3d::default() -> Camera3d {
  Camera3d::{
    decal_config: CameraDecalConfig3d::default(),
    deferred_config: CameraDeferredConfig3d::default(),
    distance_fog: None,
    volumetric_fog: None,
    atmosphere: None,
    atmosphere_settings: None,
    auto_exposure: None,
    depth_of_field: None,
  }
}

///|
pub fn Camera3d::with_decal_config(
  self : Camera3d,
  decal_config : CameraDecalConfig3d,
) -> Camera3d {
  Camera3d::{ ..self, decal_config, }
}

///|
pub fn Camera3d::with_deferred_config(
  self : Camera3d,
  deferred_config : CameraDeferredConfig3d,
) -> Camera3d {
  Camera3d::{ ..self, deferred_config, }
}

///|
pub fn Camera3d::with_distance_fog(
  self : Camera3d,
  distance_fog : DistanceFog?,
) -> Camera3d {
  Camera3d::{ ..self, distance_fog, }
}

///|
pub fn Camera3d::with_volumetric_fog(
  self : Camera3d,
  volumetric_fog : VolumetricFog?,
) -> Camera3d {
  Camera3d::{ ..self, volumetric_fog, }
}

///|
pub fn Camera3d::with_atmosphere(
  self : Camera3d,
  atmosphere : Atmosphere?,
) -> Camera3d {
  Camera3d::{ ..self, atmosphere, }
}

///|
pub fn Camera3d::with_atmosphere_settings(
  self : Camera3d,
  atmosphere_settings : AtmosphereSettings?,
) -> Camera3d {
  Camera3d::{ ..self, atmosphere_settings, }
}

///|
pub fn Camera3d::with_auto_exposure(
  self : Camera3d,
  auto_exposure : AutoExposure?,
) -> Camera3d {
  Camera3d::{ ..self, auto_exposure, }
}

///|
pub fn Camera3d::with_depth_of_field(
  self : Camera3d,
  depth_of_field : DepthOfField?,
) -> Camera3d {
  Camera3d::{ ..self, depth_of_field, }
}

///|
pub type ChromaticAberration = @post_process.ChromaticAberration

///|
pub type Vignette = @post_process.Vignette

///|
pub type MotionBlur = @post_process.MotionBlur

///|
pub type Msaa = @core_pipeline.Msaa

///|
pub type FxaaSensitivity = @post_process.FxaaSensitivity

///|
pub type Fxaa = @post_process.Fxaa

///|
pub type CustomPostProcess3d = @post_process.CustomPostProcess3d

///|
pub type DepthPrepass = @pbr_prepass.DepthPrepass

///|
pub type NormalPrepass = @pbr_prepass.NormalPrepass

///|
pub type MotionVectorPrepass = @pbr_prepass.MotionVectorPrepass

///|
pub type DeferredPrepass = @pbr_prepass.DeferredPrepass

///|
/// Marker component aligned with Bevy's `OcclusionCulling`.
pub struct OcclusionCulling {} derive(ToJson, FromJson)

///|
pub fn OcclusionCulling::default() -> OcclusionCulling {
  OcclusionCulling::{  }
}

///|
/// Marker component aligned with Bevy's `NoIndirectDrawing`.
pub struct NoIndirectDrawing {} derive(ToJson, FromJson)

///|
pub fn NoIndirectDrawing::default() -> NoIndirectDrawing {
  NoIndirectDrawing::{  }
}

///|
/// Marker component aligned with Bevy's `NotShadowCaster`.
pub struct NotShadowCaster {} derive(ToJson, FromJson)

///|
pub fn NotShadowCaster::default() -> NotShadowCaster {
  NotShadowCaster::{  }
}

///|
/// Marker component aligned with Bevy's `NotShadowReceiver`.
pub struct NotShadowReceiver {} derive(ToJson, FromJson)

///|
pub fn NotShadowReceiver::default() -> NotShadowReceiver {
  NotShadowReceiver::{  }
}

///|
/// Marker component aligned with Bevy's `TransmittedShadowReceiver`.
pub struct TransmittedShadowReceiver {} derive(ToJson, FromJson)

///|
pub fn TransmittedShadowReceiver::default() -> TransmittedShadowReceiver {
  TransmittedShadowReceiver::{  }
}

///|
/// Camera transparency settings aligned with Bevy's
/// `OrderIndependentTransparencySettings`.
pub struct OrderIndependentTransparencySettings {
  sorted_fragment_max_count : Int
  fragments_per_pixel_average : Float
  alpha_threshold : Float
} derive(ToJson, FromJson)

///|
fn oit_safe_sorted_fragment_max_count(value : Int) -> Int {
  if value < 1 {
    1
  } else {
    value
  }
}

///|
fn oit_safe_fragments_per_pixel_average(value : Float) -> Float {
  if value < 0.25F {
    0.25F
  } else {
    value
  }
}

///|
fn oit_safe_alpha_threshold(value : Float) -> Float {
  if value < 0.0F {
    0.0F
  } else if value > 1.0F {
    1.0F
  } else {
    value
  }
}

///|
pub fn OrderIndependentTransparencySettings::default() -> OrderIndependentTransparencySettings {
  OrderIndependentTransparencySettings::{
    sorted_fragment_max_count: 8,
    fragments_per_pixel_average: 4.0F,
    alpha_threshold: 0.0F,
  }
}

///|
pub fn OrderIndependentTransparencySettings::new(
  sorted_fragment_max_count : Int,
  fragments_per_pixel_average : Float,
  alpha_threshold : Float,
) -> OrderIndependentTransparencySettings {
  OrderIndependentTransparencySettings::{
    sorted_fragment_max_count: oit_safe_sorted_fragment_max_count(
      sorted_fragment_max_count,
    ),
    fragments_per_pixel_average: oit_safe_fragments_per_pixel_average(
      fragments_per_pixel_average,
    ),
    alpha_threshold: oit_safe_alpha_threshold(alpha_threshold),
  }
}

///|
pub fn OrderIndependentTransparencySettings::with_sorted_fragment_max_count(
  self : OrderIndependentTransparencySettings,
  sorted_fragment_max_count : Int,
) -> OrderIndependentTransparencySettings {
  OrderIndependentTransparencySettings::{
    ..self,
    sorted_fragment_max_count: oit_safe_sorted_fragment_max_count(
      sorted_fragment_max_count,
    ),
  }
}

///|
pub fn OrderIndependentTransparencySettings::with_fragments_per_pixel_average(
  self : OrderIndependentTransparencySettings,
  fragments_per_pixel_average : Float,
) -> OrderIndependentTransparencySettings {
  OrderIndependentTransparencySettings::{
    ..self,
    fragments_per_pixel_average: oit_safe_fragments_per_pixel_average(
      fragments_per_pixel_average,
    ),
  }
}

///|
pub fn OrderIndependentTransparencySettings::with_alpha_threshold(
  self : OrderIndependentTransparencySettings,
  alpha_threshold : Float,
) -> OrderIndependentTransparencySettings {
  OrderIndependentTransparencySettings::{
    ..self,
    alpha_threshold: oit_safe_alpha_threshold(alpha_threshold),
  }
}

///|
pub type Lightmap = @lightmap.Lightmap

///|
pub type TemporalAntiAliasing = @post_process.TemporalAntiAliasing

///|
pub type TemporalJitter = @post_process.TemporalJitter

///|
pub type Hdr = @core_pipeline.Hdr

///|
const EXPOSURE_EV100_SUNLIGHT : Float = 15.0F

///|
const EXPOSURE_EV100_OVERCAST : Float = 12.0F

///|
const EXPOSURE_EV100_INDOOR : Float = 7.0F

///|
const EXPOSURE_EV100_BLENDER : Float = 9.7F

///|
/// Camera exposure settings aligned with Bevy's `Exposure`.
pub struct Exposure {
  ev100 : Float
} derive(ToJson, FromJson)

///|
pub fn Exposure::default() -> Exposure {
  Exposure::{ ev100: EXPOSURE_EV100_BLENDER }
}

///|
pub fn Exposure::new(ev100 : Float) -> Exposure {
  Exposure::{ ev100, }
}

///|
pub fn Exposure::sunlight() -> Exposure {
  Exposure::{ ev100: EXPOSURE_EV100_SUNLIGHT }
}

///|
pub fn Exposure::overcast() -> Exposure {
  Exposure::{ ev100: EXPOSURE_EV100_OVERCAST }
}

///|
pub fn Exposure::indoor() -> Exposure {
  Exposure::{ ev100: EXPOSURE_EV100_INDOOR }
}

///|
pub fn Exposure::blender() -> Exposure {
  Exposure::{ ev100: EXPOSURE_EV100_BLENDER }
}

///|
pub fn Exposure::from_physical_camera(
  physical_camera_parameters : PhysicalCameraParameters,
) -> Exposure {
  Exposure::{ ev100: physical_camera_parameters.ev100() }
}

///|
pub fn Exposure::with_ev100(self : Exposure, ev100 : Float) -> Exposure {
  self |> ignore
  Exposure::{ ev100, }
}

///|
pub fn Exposure::exposure(self : Exposure) -> Float {
  @math.pow(2.0F, -self.ev100) / 1.2F
}

///|
fn render3d_log2(value : Float) -> Float {
  if value <= 0.0F {
    return @float.neg_infinity
  }
  let mut normalized = value
  let mut exponent = 0.0F
  while normalized < 1.0F {
    normalized = normalized * 2.0F
    exponent = exponent - 1.0F
  }
  while normalized >= 2.0F {
    normalized = normalized / 2.0F
    exponent = exponent + 1.0F
  }
  let mut fraction = 0.0F
  let mut factor = 0.5F
  let mut current = normalized
  for _ in 0..<16 {
    current = current * current
    if current >= 2.0F {
      current = current / 2.0F
      fraction = fraction + factor
    }
    factor = factor / 2.0F
  }
  exponent + fraction
}

///|
/// Physical camera parameters aligned with Bevy's `PhysicalCameraParameters`.
pub(all) struct PhysicalCameraParameters {
  mut aperture_f_stops : Float
  mut shutter_speed_s : Float
  mut sensitivity_iso : Float
  mut sensor_height : Float
} derive(ToJson, FromJson)

///|
pub fn PhysicalCameraParameters::default() -> PhysicalCameraParameters {
  PhysicalCameraParameters::{
    aperture_f_stops: 1.0F,
    shutter_speed_s: 1.0F / 125.0F,
    sensitivity_iso: 100.0F,
    sensor_height: 0.01866F,
  }
}

///|
pub fn PhysicalCameraParameters::ev100(
  self : PhysicalCameraParameters,
) -> Float {
  let numerator = self.aperture_f_stops * self.aperture_f_stops * 100.0F
  let denominator = self.shutter_speed_s * self.sensitivity_iso
  render3d_log2(numerator / denominator)
}

///|
pub type ColorGradingRange = @post_process.ColorGradingRange

///|
pub type ColorGradingGlobal = @post_process.ColorGradingGlobal

///|
pub type ColorGradingSection = @post_process.ColorGradingSection

///|
pub type ColorGrading = @post_process.ColorGrading

///|
pub type Tonemapping = @post_process.Tonemapping

///|
pub type DebandDither = @post_process.DebandDither

///|
pub type BloomPrefilter = @post_process.BloomPrefilter

///|
pub type BloomCompositeMode = @post_process.BloomCompositeMode

///|
pub type Bloom = @post_process.Bloom

///|
/// Camera skybox settings aligned with Bevy's `Skybox`.
pub struct Skybox {
  image : @asset.Handle[@asset.Image]?
  brightness : Float
  rotation : @math.Quat
} derive(ToJson, FromJson)

///|
pub fn Skybox::default() -> Skybox {
  Skybox::{ image: None, brightness: 0.0F, rotation: @math.Quat::identity() }
}

///|
pub fn Skybox::new(
  image : @asset.Handle[@asset.Image],
  brightness : Float,
) -> Skybox {
  Skybox::{
    ..Skybox::default(),
    image: Some(image),
    brightness: if brightness < 0.0F {
      0.0F
    } else {
      brightness
    },
  }
}

///|
pub fn Skybox::with_image(
  self : Skybox,
  image : @asset.Handle[@asset.Image]?,
) -> Skybox {
  Skybox::{ ..self, image, }
}

///|
pub fn Skybox::with_brightness(self : Skybox, brightness : Float) -> Skybox {
  Skybox::{
    ..self,
    brightness: if brightness < 0.0F {
      0.0F
    } else {
      brightness
    },
  }
}

///|
pub fn Skybox::with_rotation(self : Skybox, rotation : @math.Quat) -> Skybox {
  Skybox::{ ..self, rotation, }
}

///|
pub type ScreenSpaceAmbientOcclusionQualityLevel = @post_process.ScreenSpaceAmbientOcclusionQualityLevel

///|
pub type ScreenSpaceAmbientOcclusion = @post_process.ScreenSpaceAmbientOcclusion

///|
/// Camera shadow filtering mode aligned with Bevy's `ShadowFilteringMethod`.
pub(all) enum ShadowFilteringMethod {
  Hardware2x2
  Gaussian
  Temporal
} derive(Eq, Debug, ToJson, FromJson)

///|
pub fn ShadowFilteringMethod::default() -> ShadowFilteringMethod {
  ShadowFilteringMethod::Gaussian
}

///|
/// Camera screen-space transmission quality aligned with Bevy's
/// `ScreenSpaceTransmissionQuality`.
pub type ScreenSpaceTransmissionQuality = @post_process.ScreenSpaceTransmissionQuality

///|
fn screen_space_transmission_blur_taps(
  quality : ScreenSpaceTransmissionQuality,
) -> Int {
  @post_process.screen_space_transmission_blur_taps(quality)
}

///|
pub type ScreenSpaceTransmission = @post_process.ScreenSpaceTransmission

///|
pub type ScreenSpaceReflections = @post_process.ScreenSpaceReflections
