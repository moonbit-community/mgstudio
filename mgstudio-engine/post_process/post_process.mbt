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
/// Post-process API boundary.
/// Runtime implementation currently lives in `Milky2018/mgstudio/pbr`.

///|
pub type Fxaa = @pbr.Fxaa

///|
pub type FxaaSensitivity = @pbr.FxaaSensitivity

///|
pub type Tonemapping = @pbr.Tonemapping

///|
pub type DebandDither = @pbr.DebandDither

///|
pub type Bloom = @pbr.Bloom

///|
pub type BloomPrefilter = @pbr.BloomPrefilter

///|
pub type BloomCompositeMode = @pbr.BloomCompositeMode

///|
pub type ChromaticAberration = @pbr.ChromaticAberration

///|
pub type Vignette = @pbr.Vignette

///|
pub type MotionBlur = @pbr.MotionBlur

///|
pub type TemporalAntiAliasing = @pbr.TemporalAntiAliasing

///|
pub type TemporalJitter = @pbr.TemporalJitter

///|
pub type ColorGrading = @pbr.ColorGrading

///|
pub type ColorGradingRange = @pbr.ColorGradingRange

///|
pub type ColorGradingGlobal = @pbr.ColorGradingGlobal

///|
pub type ColorGradingSection = @pbr.ColorGradingSection

///|
pub type ScreenSpaceAmbientOcclusion = @pbr.ScreenSpaceAmbientOcclusion

///|
pub type ScreenSpaceAmbientOcclusionQualityLevel = @pbr.ScreenSpaceAmbientOcclusionQualityLevel

///|
pub type ScreenSpaceReflections = @pbr.ScreenSpaceReflections

///|
pub type ScreenSpaceTransmission = @pbr.ScreenSpaceTransmission

///|
pub type ScreenSpaceTransmissionQuality = @pbr.ScreenSpaceTransmissionQuality

///|
pub let ecs_key_fxaa : @ecs.ComponentKey[Fxaa] = @pbr.ecs_key_fxaa

///|
pub let ecs_key_tonemapping : @ecs.ComponentKey[Tonemapping] = @pbr.ecs_key_tonemapping

///|
pub let ecs_key_deband_dither : @ecs.ComponentKey[DebandDither] = @pbr.ecs_key_deband_dither

///|
pub let ecs_key_bloom : @ecs.ComponentKey[Bloom] = @pbr.ecs_key_bloom

///|
pub let ecs_key_chromatic_aberration : @ecs.ComponentKey[ChromaticAberration] = @pbr.ecs_key_chromatic_aberration

///|
pub let ecs_key_vignette : @ecs.ComponentKey[Vignette] = @pbr.ecs_key_vignette

///|
pub let ecs_key_motion_blur : @ecs.ComponentKey[MotionBlur] = @pbr.ecs_key_motion_blur

///|
pub let ecs_key_temporal_anti_aliasing : @ecs.ComponentKey[TemporalAntiAliasing] = @pbr.ecs_key_temporal_anti_aliasing

///|
pub let ecs_key_temporal_jitter : @ecs.ComponentKey[TemporalJitter] = @pbr.ecs_key_temporal_jitter

///|
pub let ecs_key_color_grading : @ecs.ComponentKey[ColorGrading] = @pbr.ecs_key_color_grading

///|
pub let ecs_key_screen_space_ambient_occlusion : @ecs.ComponentKey[
  ScreenSpaceAmbientOcclusion,
] = @pbr.ecs_key_screen_space_ambient_occlusion

///|
pub let ecs_key_screen_space_reflections : @ecs.ComponentKey[
  ScreenSpaceReflections,
] = @pbr.ecs_key_screen_space_reflections

///|
pub let ecs_key_screen_space_transmission : @ecs.ComponentKey[
  ScreenSpaceTransmission,
] = @pbr.ecs_key_screen_space_transmission
