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
  ForwardAndClustered
}

///|
pub struct CameraDecalConfig3d {
  mode : DecalRenderMode3d
  requires_depth_prepass : Bool
  clustered_requires_deferred_prepass : Bool
} derive(ToJson, FromJson)

///|
pub fn CameraDecalConfig3d::CameraDecalConfig3d() -> CameraDecalConfig3d {
  {
    mode: ForwardAndClustered,
    requires_depth_prepass: true,
    clustered_requires_deferred_prepass: false,
  }
}

///|
pub fn CameraDecalConfig3d::with_mode(
  self : CameraDecalConfig3d,
  mode : DecalRenderMode3d,
) -> CameraDecalConfig3d {
  { ..self, mode, }
}

///|
pub fn CameraDecalConfig3d::with_requires_depth_prepass(
  self : CameraDecalConfig3d,
  requires_depth_prepass : Bool,
) -> CameraDecalConfig3d {
  { ..self, requires_depth_prepass, }
}

///|
pub fn CameraDecalConfig3d::with_clustered_requires_deferred_prepass(
  self : CameraDecalConfig3d,
  clustered_requires_deferred_prepass : Bool,
) -> CameraDecalConfig3d {
  { ..self, clustered_requires_deferred_prepass, }
}

///|
pub(all) enum CameraDeferredMode3d {
  Auto
  Forward
  Deferred
} derive(Eq, Debug, ToJson, FromJson)

///|
pub fn CameraDeferredMode3d::default() -> CameraDeferredMode3d {
  Auto
}

///|
pub struct CameraDeferredConfig3d {
  mode : CameraDeferredMode3d
  requires_deferred_prepass : Bool
} derive(ToJson, FromJson)

///|
pub fn CameraDeferredConfig3d::CameraDeferredConfig3d() -> CameraDeferredConfig3d {
  { mode: Auto, requires_deferred_prepass: false }
}

///|
pub fn CameraDeferredConfig3d::with_mode(
  self : CameraDeferredConfig3d,
  mode : CameraDeferredMode3d,
) -> CameraDeferredConfig3d {
  { ..self, mode, }
}

///|
pub fn CameraDeferredConfig3d::with_requires_deferred_prepass(
  self : CameraDeferredConfig3d,
  requires_deferred_prepass : Bool,
) -> CameraDeferredConfig3d {
  { ..self, requires_deferred_prepass, }
}

///|
// Re-exports of the Bevy `bevy_post_process` owners. The components live in
// `post_process/auto_exposure` and `post_process/dof`; pbr consumes them for
// the extracted view payload and the legacy `Camera3dBundle`.
pub type AutoExposure = @post_process_auto_exposure.AutoExposure

///|
pub type AutoExposureCompensationCurve = @post_process_auto_exposure.AutoExposureCompensationCurve

///|
pub type AutoExposureCompensationCurveError = @post_process_auto_exposure.AutoExposureCompensationCurveError

///|
pub type DepthOfField = @post_process_dof.DepthOfField

///|
pub type DepthOfFieldMode = @post_process_dof.DepthOfFieldMode

///|
/// Camera component aligned with Bevy's `Camera3d`.
pub type Camera3dDepthLoadOp = @camera_components3d.Camera3dDepthLoadOp

///|
pub type Camera3dDepthTextureUsage = @camera_components3d.Camera3dDepthTextureUsage

///|
pub type Camera3d = @camera_components3d.Camera3d

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
pub type OcclusionCulling = @render_occlusion_culling.OcclusionCulling

///|
pub type NoIndirectDrawing = @render_view.NoIndirectDrawing

///|
pub type NotShadowCaster = @light.NotShadowCaster

///|
pub type NotShadowReceiver = @light.NotShadowReceiver

///|
pub type TransmittedShadowReceiver = @light.TransmittedShadowReceiver

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
pub fn OrderIndependentTransparencySettings::OrderIndependentTransparencySettings() -> OrderIndependentTransparencySettings {
  {
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
  {
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
  {
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
  {
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
  { ..self, alpha_threshold: oit_safe_alpha_threshold(alpha_threshold) }
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
pub type Exposure = @camera_camera.Exposure

///|
pub type PhysicalCameraParameters = @camera_camera.PhysicalCameraParameters

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
pub type Skybox = @light.Skybox

///|
pub type ScreenSpaceAmbientOcclusionQualityLevel = @post_process.ScreenSpaceAmbientOcclusionQualityLevel

///|
pub type ScreenSpaceAmbientOcclusion = @post_process.ScreenSpaceAmbientOcclusion

///|
pub type ShadowFilteringMethod = @light.ShadowFilteringMethod

///|
/// Camera screen-space transmission quality aligned with Bevy's
/// `ScreenSpaceTransmissionQuality`.
pub type ScreenSpaceTransmissionQuality = @transmission.ScreenSpaceTransmissionQuality

///|
fn screen_space_transmission_blur_taps(
  quality : ScreenSpaceTransmissionQuality,
) -> Int {
  @transmission.screen_space_transmission_blur_taps(quality)
}

///|
pub type ScreenSpaceTransmission = @transmission.ScreenSpaceTransmission

///|
pub type ScreenSpaceReflections = @post_process.ScreenSpaceReflections
