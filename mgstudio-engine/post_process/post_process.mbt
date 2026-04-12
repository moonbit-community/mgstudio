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
/// Post-process runtime and ECS surfaces aligned with Bevy post-process modules.

///|
pub type ChromaticAberration = @post_process_effect_stack.ChromaticAberration

///|
pub type Vignette = @post_process_effect_stack.Vignette

///|
pub type MotionBlur = @post_process_motion_blur.MotionBlur

///|
pub(all) enum FxaaSensitivity {
  Low
  Medium
  High
  Ultra
  Extreme
} derive(Eq, Debug, ToJson, FromJson)

///|
pub fn FxaaSensitivity::default() -> FxaaSensitivity {
  FxaaSensitivity::High
}

///|
/// Camera post-process settings aligned with Bevy's `Fxaa`.
pub struct Fxaa {
  enabled : Bool
  edge_threshold : FxaaSensitivity
  edge_threshold_min : FxaaSensitivity
} derive(ToJson, FromJson)

///|
pub fn Fxaa::default() -> Fxaa {
  Fxaa::{
    enabled: true,
    edge_threshold: FxaaSensitivity::High,
    edge_threshold_min: FxaaSensitivity::High,
  }
}

///|
pub fn Fxaa::new(enabled : Bool) -> Fxaa {
  Fxaa::{ ..Fxaa::default(), enabled, }
}

///|
pub fn Fxaa::new_with_sensitivity(
  enabled : Bool,
  edge_threshold : FxaaSensitivity,
  edge_threshold_min : FxaaSensitivity,
) -> Fxaa {
  Fxaa::{ enabled, edge_threshold, edge_threshold_min }
}

///|
pub fn Fxaa::with_enabled(self : Fxaa, enabled : Bool) -> Fxaa {
  Fxaa::{ ..self, enabled, }
}

///|
pub fn Fxaa::with_edge_threshold(
  self : Fxaa,
  edge_threshold : FxaaSensitivity,
) -> Fxaa {
  Fxaa::{ ..self, edge_threshold, }
}

///|
pub fn Fxaa::with_edge_threshold_min(
  self : Fxaa,
  edge_threshold_min : FxaaSensitivity,
) -> Fxaa {
  Fxaa::{ ..self, edge_threshold_min, }
}

///|
pub fn Fxaa::with_sensitivity(
  self : Fxaa,
  sensitivity : FxaaSensitivity,
) -> Fxaa {
  Fxaa::{ ..self, edge_threshold: sensitivity, edge_threshold_min: sensitivity }
}

///|
/// Generic fullscreen custom post-process settings for 3D cameras.
///
/// Shader contracts follow Bevy-style post-process fullscreen passes:
/// `@group(0) @binding(0)` source texture, `@group(0) @binding(1)` sampler,
/// and `@group(0) @binding(2)` a uniform `vec4<f32>` parameters payload.
pub struct CustomPostProcess3d {
  enabled : Bool
  shader_path : String
  fragment_entry : String
  uniform_x : Float
  uniform_y : Float
  uniform_z : Float
  uniform_w : Float
} derive(ToJson, FromJson)

///|
pub fn CustomPostProcess3d::default() -> CustomPostProcess3d {
  CustomPostProcess3d::{
    enabled: false,
    shader_path: "",
    fragment_entry: "fragment_main",
    uniform_x: 0.0F,
    uniform_y: 0.0F,
    uniform_z: 0.0F,
    uniform_w: 0.0F,
  }
}

///|
pub fn CustomPostProcess3d::new(shader_path : String) -> CustomPostProcess3d {
  CustomPostProcess3d::{ ..CustomPostProcess3d::default(), shader_path, }
}

///|
pub fn CustomPostProcess3d::with_enabled(
  self : CustomPostProcess3d,
  enabled : Bool,
) -> CustomPostProcess3d {
  CustomPostProcess3d::{ ..self, enabled, }
}

///|
pub fn CustomPostProcess3d::with_shader_path(
  self : CustomPostProcess3d,
  shader_path : String,
) -> CustomPostProcess3d {
  CustomPostProcess3d::{ ..self, shader_path, }
}

///|
pub fn CustomPostProcess3d::with_fragment_entry(
  self : CustomPostProcess3d,
  fragment_entry : String,
) -> CustomPostProcess3d {
  CustomPostProcess3d::{ ..self, fragment_entry, }
}

///|
pub fn CustomPostProcess3d::with_uniform(
  self : CustomPostProcess3d,
  uniform_x : Float,
  uniform_y : Float,
  uniform_z : Float,
  uniform_w : Float,
) -> CustomPostProcess3d {
  CustomPostProcess3d::{ ..self, uniform_x, uniform_y, uniform_z, uniform_w }
}

///|
pub fn CustomPostProcess3d::with_intensity(
  self : CustomPostProcess3d,
  intensity : Float,
) -> CustomPostProcess3d {
  CustomPostProcess3d::{ ..self, uniform_x: intensity }
}

///|
/// Camera temporal AA settings aligned with Bevy's `TemporalAntiAliasing`.
pub struct TemporalAntiAliasing {
  reset : Bool
} derive(ToJson, FromJson)

///|
pub fn TemporalAntiAliasing::default() -> TemporalAntiAliasing {
  TemporalAntiAliasing::{ reset: true }
}

///|
pub fn TemporalAntiAliasing::new(reset : Bool) -> TemporalAntiAliasing {
  TemporalAntiAliasing::{ reset, }
}

///|
pub fn TemporalAntiAliasing::with_reset(
  self : TemporalAntiAliasing,
  reset : Bool,
) -> TemporalAntiAliasing {
  if self.reset == reset {
    self
  } else {
    TemporalAntiAliasing::{ reset, }
  }
}

///|
/// Camera jitter settings aligned with Bevy's `TemporalJitter`.
pub struct TemporalJitter {
  offset : @math.Vec2
} derive(ToJson, FromJson)

///|
pub fn TemporalJitter::default() -> TemporalJitter {
  TemporalJitter::{ offset: @math.Vec2::new(0.0F, 0.0F) }
}

///|
pub fn TemporalJitter::new(offset : @math.Vec2) -> TemporalJitter {
  TemporalJitter::{ offset, }
}

///|
pub fn TemporalJitter::with_offset(
  self : TemporalJitter,
  offset : @math.Vec2,
) -> TemporalJitter {
  self |> ignore
  TemporalJitter::{ offset, }
}

///|
/// Midtone range controls aligned with Bevy's `Range<f32>`-based surface.
pub(all) struct ColorGradingRange {
  mut start : Float
  mut end_ : Float
} derive(ToJson, FromJson)

///|
pub fn ColorGradingRange::default() -> ColorGradingRange {
  ColorGradingRange::{ start: 0.2F, end_: 0.7F }
}

///|
fn color_grading_range_copy(value : ColorGradingRange) -> ColorGradingRange {
  let out = ColorGradingRange::default()
  out.start = value.start
  out.end_ = value.end_
  out
}

///|
/// Global color-grading controls aligned with Bevy's `ColorGradingGlobal`.
pub(all) struct ColorGradingGlobal {
  mut exposure : Float
  mut temperature : Float
  mut tint : Float
  mut hue : Float
  mut post_saturation : Float
  mut midtones_range : ColorGradingRange
} derive(ToJson, FromJson)

///|
pub fn ColorGradingGlobal::default() -> ColorGradingGlobal {
  ColorGradingGlobal::{
    exposure: 0.0F,
    temperature: 0.0F,
    tint: 0.0F,
    hue: 0.0F,
    post_saturation: 1.0F,
    midtones_range: ColorGradingRange::default(),
  }
}

///|
fn color_grading_global_copy(value : ColorGradingGlobal) -> ColorGradingGlobal {
  let out = ColorGradingGlobal::default()
  out.exposure = value.exposure
  out.temperature = value.temperature
  out.tint = value.tint
  out.hue = value.hue
  out.post_saturation = value.post_saturation
  out.midtones_range = color_grading_range_copy(value.midtones_range)
  out
}

///|
/// Sectional color-grading controls aligned with Bevy's `ColorGradingSection`.
pub(all) struct ColorGradingSection {
  mut saturation : Float
  mut contrast : Float
  mut gamma : Float
  mut gain : Float
  mut lift : Float
} derive(ToJson, FromJson)

///|
pub fn ColorGradingSection::default() -> ColorGradingSection {
  ColorGradingSection::{
    saturation: 1.0F,
    contrast: 1.0F,
    gamma: 1.0F,
    gain: 1.0F,
    lift: 0.0F,
  }
}

///|
fn color_grading_section_copy(
  value : ColorGradingSection,
) -> ColorGradingSection {
  let out = ColorGradingSection::default()
  out.saturation = value.saturation
  out.contrast = value.contrast
  out.gamma = value.gamma
  out.gain = value.gain
  out.lift = value.lift
  out
}

///|
/// Camera color grading settings aligned with Bevy's `ColorGrading`.
pub(all) struct ColorGrading {
  mut global : ColorGradingGlobal
  mut shadows : ColorGradingSection
  mut midtones : ColorGradingSection
  mut highlights : ColorGradingSection
} derive(ToJson, FromJson)

///|
pub fn ColorGrading::default() -> ColorGrading {
  ColorGrading::{
    global: ColorGradingGlobal::default(),
    shadows: ColorGradingSection::default(),
    midtones: ColorGradingSection::default(),
    highlights: ColorGradingSection::default(),
  }
}

///|
pub fn ColorGrading::with_identical_sections(
  global : ColorGradingGlobal,
  section : ColorGradingSection,
) -> ColorGrading {
  let color_grading = ColorGrading::default()
  color_grading.global = color_grading_global_copy(global)
  color_grading.shadows = color_grading_section_copy(section)
  color_grading.midtones = color_grading_section_copy(section)
  color_grading.highlights = color_grading_section_copy(section)
  color_grading
}

///|
pub fn ColorGrading::all_sections(
  self : ColorGrading,
) -> Iter[ColorGradingSection] {
  [self.shadows, self.midtones, self.highlights].iter()
}

///|
pub fn ColorGrading::all_sections_mut(
  self : ColorGrading,
) -> Iter[ColorGradingSection] {
  [self.shadows, self.midtones, self.highlights].iter()
}

///|
/// Camera tonemapping mode aligned with Bevy's `Tonemapping`.
pub(all) enum Tonemapping {
  None
  Reinhard
  ReinhardLuminance
  AcesFitted
  AgX
  SomewhatBoringDisplayTransform
  TonyMcMapface
  BlenderFilmic
} derive(Eq, Hash, Debug, ToJson, FromJson)

///|
pub fn Tonemapping::default() -> Tonemapping {
  Tonemapping::TonyMcMapface
}

///|
/// Enables / disables screen-space deband dithering in the tonemapping pass.
pub(all) enum DebandDither {
  Disabled
  Enabled
} derive(Eq, Debug, ToJson, FromJson)

///|
pub fn DebandDither::default() -> DebandDither {
  DebandDither::Disabled
}

///|
pub struct BloomPrefilter {
  threshold : Float
  threshold_softness : Float
} derive(ToJson, FromJson)

///|
pub fn BloomPrefilter::default() -> BloomPrefilter {
  BloomPrefilter::{ threshold: 0.0F, threshold_softness: 0.0F }
}

///|
pub fn BloomPrefilter::new(
  threshold : Float,
  threshold_softness : Float,
) -> BloomPrefilter {
  BloomPrefilter::{
    threshold: if threshold < 0.0F {
      0.0F
    } else {
      threshold
    },
    threshold_softness: if threshold_softness < 0.0F {
      0.0F
    } else if threshold_softness > 1.0F {
      1.0F
    } else {
      threshold_softness
    },
  }
}

///|
pub fn BloomPrefilter::with_threshold(
  self : BloomPrefilter,
  threshold : Float,
) -> BloomPrefilter {
  BloomPrefilter::new(threshold, self.threshold_softness)
}

///|
pub fn BloomPrefilter::with_threshold_softness(
  self : BloomPrefilter,
  threshold_softness : Float,
) -> BloomPrefilter {
  BloomPrefilter::new(self.threshold, threshold_softness)
}

///|
pub(all) enum BloomCompositeMode {
  EnergyConserving
  Additive
} derive(Eq, Debug, ToJson, FromJson)

///|
pub fn BloomCompositeMode::default() -> BloomCompositeMode {
  BloomCompositeMode::EnergyConserving
}

///|
const BLOOM_DEFAULT_MAX_MIP_DIMENSION : Int = 512

///|
/// Camera bloom settings aligned with Bevy's `Bloom`.
pub struct Bloom {
  intensity : Float
  low_frequency_boost : Float
  low_frequency_boost_curvature : Float
  high_pass_frequency : Float
  prefilter : BloomPrefilter
  composite_mode : BloomCompositeMode
  max_mip_dimension : Int
  scale : @math.Vec2
} derive(ToJson, FromJson)

///|
pub fn Bloom::default() -> Bloom {
  Bloom::{
    intensity: 0.15F,
    low_frequency_boost: 0.7F,
    low_frequency_boost_curvature: 0.95F,
    high_pass_frequency: 1.0F,
    prefilter: BloomPrefilter::default(),
    composite_mode: BloomCompositeMode::EnergyConserving,
    max_mip_dimension: BLOOM_DEFAULT_MAX_MIP_DIMENSION,
    scale: @math.Vec2::new(1.0F, 1.0F),
  }
}

///|
pub fn Bloom::natural() -> Bloom {
  Bloom::default()
}

///|
pub fn Bloom::anamorphic() -> Bloom {
  Bloom::{
    ..Bloom::default(),
    max_mip_dimension: BLOOM_DEFAULT_MAX_MIP_DIMENSION * 2,
    scale: @math.Vec2::new(4.0F, 1.0F),
  }
}

///|
pub fn Bloom::old_school() -> Bloom {
  Bloom::{
    ..Bloom::default(),
    intensity: 0.05F,
    prefilter: BloomPrefilter::new(0.6F, 0.2F),
    composite_mode: BloomCompositeMode::Additive,
  }
}

///|
pub fn Bloom::screen_blur() -> Bloom {
  Bloom::{
    ..Bloom::default(),
    intensity: 1.0F,
    low_frequency_boost: 0.0F,
    low_frequency_boost_curvature: 0.0F,
    high_pass_frequency: 1.0F / 3.0F,
  }
}

///|
pub fn Bloom::new(intensity : Float) -> Bloom {
  Bloom::{
    ..Bloom::default(),
    intensity: if intensity < 0.0F {
      0.0F
    } else {
      intensity
    },
  }
}

///|
pub fn Bloom::with_intensity(self : Bloom, intensity : Float) -> Bloom {
  Bloom::{ ..self, intensity: if intensity < 0.0F { 0.0F } else { intensity } }
}

///|
pub fn Bloom::with_low_frequency_boost(
  self : Bloom,
  low_frequency_boost : Float,
) -> Bloom {
  Bloom::{
    ..self,
    low_frequency_boost: if low_frequency_boost < 0.0F {
      0.0F
    } else if low_frequency_boost > 1.0F {
      1.0F
    } else {
      low_frequency_boost
    },
  }
}

///|
pub fn Bloom::with_low_frequency_boost_curvature(
  self : Bloom,
  low_frequency_boost_curvature : Float,
) -> Bloom {
  Bloom::{
    ..self,
    low_frequency_boost_curvature: if low_frequency_boost_curvature < 0.0F {
      0.0F
    } else if low_frequency_boost_curvature > 1.0F {
      1.0F
    } else {
      low_frequency_boost_curvature
    },
  }
}

///|
pub fn Bloom::with_high_pass_frequency(
  self : Bloom,
  high_pass_frequency : Float,
) -> Bloom {
  Bloom::{
    ..self,
    high_pass_frequency: if high_pass_frequency < 0.0F {
      0.0F
    } else if high_pass_frequency > 1.0F {
      1.0F
    } else {
      high_pass_frequency
    },
  }
}

///|
pub fn Bloom::with_prefilter(
  self : Bloom,
  threshold : Float,
  threshold_softness : Float,
) -> Bloom {
  Bloom::{
    ..self,
    prefilter: BloomPrefilter::new(threshold, threshold_softness),
  }
}

///|
pub fn Bloom::with_prefilter_settings(
  self : Bloom,
  prefilter : BloomPrefilter,
) -> Bloom {
  Bloom::{
    ..self,
    prefilter: BloomPrefilter::new(
      prefilter.threshold,
      prefilter.threshold_softness,
    ),
  }
}

///|
pub fn Bloom::with_composite_mode(
  self : Bloom,
  composite_mode : BloomCompositeMode,
) -> Bloom {
  Bloom::{ ..self, composite_mode, }
}

///|
pub fn Bloom::with_max_mip_dimension(
  self : Bloom,
  max_mip_dimension : Int,
) -> Bloom {
  Bloom::{
    ..self,
    max_mip_dimension: if max_mip_dimension < 4 {
      4
    } else {
      max_mip_dimension
    },
  }
}

///|
pub fn Bloom::with_scale(self : Bloom, scale : @math.Vec2) -> Bloom {
  Bloom::{
    ..self,
    scale: @math.Vec2::new(
      if scale.x < 0.0F {
        0.0F
      } else {
        scale.x
      },
      if scale.y < 0.0F {
        0.0F
      } else {
        scale.y
      },
    ),
  }
}

///|
pub fn Bloom::with_scale_x(self : Bloom, scale_x : Float) -> Bloom {
  self.with_scale(@math.Vec2::new(scale_x, self.scale.y))
}

///|
pub fn Bloom::with_scale_y(self : Bloom, scale_y : Float) -> Bloom {
  self.with_scale(@math.Vec2::new(self.scale.x, scale_y))
}

///|
pub(all) enum ScreenSpaceAmbientOcclusionQualityLevel {
  Low
  Medium
  High
  Ultra
} derive(Eq, Debug, ToJson, FromJson)

///|
pub fn ScreenSpaceAmbientOcclusionQualityLevel::default() -> ScreenSpaceAmbientOcclusionQualityLevel {
  ScreenSpaceAmbientOcclusionQualityLevel::High
}

///|
/// Camera ambient occlusion settings aligned with Bevy's
/// `ScreenSpaceAmbientOcclusion`.
pub struct ScreenSpaceAmbientOcclusion {
  quality_level : ScreenSpaceAmbientOcclusionQualityLevel
  constant_object_thickness : Float
} derive(ToJson, FromJson)

///|
pub fn ScreenSpaceAmbientOcclusion::default() -> ScreenSpaceAmbientOcclusion {
  ScreenSpaceAmbientOcclusion::{
    quality_level: ScreenSpaceAmbientOcclusionQualityLevel::default(),
    constant_object_thickness: 0.25F,
  }
}

///|
pub fn ScreenSpaceAmbientOcclusion::with_quality_level(
  self : ScreenSpaceAmbientOcclusion,
  quality_level : ScreenSpaceAmbientOcclusionQualityLevel,
) -> ScreenSpaceAmbientOcclusion {
  ScreenSpaceAmbientOcclusion::{ ..self, quality_level, }
}

///|
pub fn ScreenSpaceAmbientOcclusion::with_constant_object_thickness(
  self : ScreenSpaceAmbientOcclusion,
  constant_object_thickness : Float,
) -> ScreenSpaceAmbientOcclusion {
  ScreenSpaceAmbientOcclusion::{
    ..self,
    constant_object_thickness: if constant_object_thickness < 0.0F {
      0.0F
    } else {
      constant_object_thickness
    },
  }
}

///|
/// Camera screen-space transmission quality aligned with Bevy's
/// `ScreenSpaceTransmissionQuality`.
pub type ScreenSpaceTransmissionQuality = @pbr_transmission.ScreenSpaceTransmissionQuality

///|
pub fn screen_space_transmission_blur_taps(
  quality : ScreenSpaceTransmissionQuality,
) -> Int {
  @pbr_transmission.screen_space_transmission_blur_taps(quality)
}

///|
/// Camera screen-space transmission settings aligned with Bevy's
/// `ScreenSpaceTransmission`.
pub type ScreenSpaceTransmission = @pbr_transmission.ScreenSpaceTransmission

///|
fn minf(a : Float, b : Float) -> Float {
  if a < b {
    a
  } else {
    b
  }
}

///|
fn maxf(a : Float, b : Float) -> Float {
  if a > b {
    a
  } else {
    b
  }
}

///|
fn clamp01(value : Float) -> Float {
  if value < 0.0F {
    0.0F
  } else if value > 1.0F {
    1.0F
  } else {
    value
  }
}

///|
fn screen_space_reflections_safe_range(
  start : Float,
  end_ : Float,
) -> (Float, Float) {
  let safe_start = clamp01(start)
  let safe_end = clamp01(end_)
  (minf(safe_start, safe_end), maxf(safe_start, safe_end))
}

///|
fn screen_space_reflections_safe_thickness(thickness : Float) -> Float {
  if thickness < 0.0F {
    0.0F
  } else {
    thickness
  }
}

///|
fn screen_space_reflections_safe_linear_steps(linear_steps : Int) -> Int {
  if linear_steps <= 0 {
    1
  } else {
    linear_steps
  }
}

///|
fn screen_space_reflections_safe_linear_march_exponent(
  linear_march_exponent : Float,
) -> Float {
  if linear_march_exponent <= 0.0F {
    1.0F
  } else {
    linear_march_exponent
  }
}

///|
fn screen_space_reflections_safe_bisection_steps(bisection_steps : Int) -> Int {
  if bisection_steps < 0 {
    0
  } else {
    bisection_steps
  }
}

///|
pub struct ScreenSpaceReflections {
  min_perceptual_roughness_start : Float
  min_perceptual_roughness_end : Float
  max_perceptual_roughness_start : Float
  max_perceptual_roughness_end : Float
  thickness : Float
  linear_steps : Int
  linear_march_exponent : Float
  edge_fadeout_start : Float
  edge_fadeout_end : Float
  bisection_steps : Int
  use_secant : Bool
} derive(ToJson, FromJson)

///|
pub fn ScreenSpaceReflections::default() -> ScreenSpaceReflections {
  let (min_start, min_end) = screen_space_reflections_safe_range(0.08F, 0.12F)
  let (max_start, max_end) = screen_space_reflections_safe_range(0.55F, 0.6F)
  let (edge_start, edge_end) = screen_space_reflections_safe_range(0.0F, 0.0F)
  ScreenSpaceReflections::{
    min_perceptual_roughness_start: min_start,
    min_perceptual_roughness_end: min_end,
    max_perceptual_roughness_start: max_start,
    max_perceptual_roughness_end: max_end,
    thickness: screen_space_reflections_safe_thickness(0.25F),
    linear_steps: screen_space_reflections_safe_linear_steps(10),
    linear_march_exponent: screen_space_reflections_safe_linear_march_exponent(
      1.0F,
    ),
    edge_fadeout_start: edge_start,
    edge_fadeout_end: edge_end,
    bisection_steps: screen_space_reflections_safe_bisection_steps(5),
    use_secant: true,
  }
}

///|
pub fn ScreenSpaceReflections::with_min_perceptual_roughness(
  self : ScreenSpaceReflections,
  start : Float,
  end_ : Float,
) -> ScreenSpaceReflections {
  let (safe_start, safe_end) = screen_space_reflections_safe_range(start, end_)
  ScreenSpaceReflections::{
    ..self,
    min_perceptual_roughness_start: safe_start,
    min_perceptual_roughness_end: safe_end,
  }
}

///|
pub fn ScreenSpaceReflections::with_max_perceptual_roughness(
  self : ScreenSpaceReflections,
  start : Float,
  end_ : Float,
) -> ScreenSpaceReflections {
  let (safe_start, safe_end) = screen_space_reflections_safe_range(start, end_)
  ScreenSpaceReflections::{
    ..self,
    max_perceptual_roughness_start: safe_start,
    max_perceptual_roughness_end: safe_end,
  }
}

///|
pub fn ScreenSpaceReflections::with_edge_fadeout(
  self : ScreenSpaceReflections,
  start : Float,
  end_ : Float,
) -> ScreenSpaceReflections {
  let (safe_start, safe_end) = screen_space_reflections_safe_range(start, end_)
  ScreenSpaceReflections::{
    ..self,
    edge_fadeout_start: safe_start,
    edge_fadeout_end: safe_end,
  }
}

///|
pub fn ScreenSpaceReflections::with_thickness(
  self : ScreenSpaceReflections,
  thickness : Float,
) -> ScreenSpaceReflections {
  ScreenSpaceReflections::{
    ..self,
    thickness: screen_space_reflections_safe_thickness(thickness),
  }
}

///|
pub fn ScreenSpaceReflections::with_linear_steps(
  self : ScreenSpaceReflections,
  linear_steps : Int,
) -> ScreenSpaceReflections {
  ScreenSpaceReflections::{
    ..self,
    linear_steps: screen_space_reflections_safe_linear_steps(linear_steps),
  }
}

///|
pub fn ScreenSpaceReflections::with_linear_march_exponent(
  self : ScreenSpaceReflections,
  linear_march_exponent : Float,
) -> ScreenSpaceReflections {
  ScreenSpaceReflections::{
    ..self,
    linear_march_exponent: screen_space_reflections_safe_linear_march_exponent(
      linear_march_exponent,
    ),
  }
}

///|
pub fn ScreenSpaceReflections::with_bisection_steps(
  self : ScreenSpaceReflections,
  bisection_steps : Int,
) -> ScreenSpaceReflections {
  ScreenSpaceReflections::{
    ..self,
    bisection_steps: screen_space_reflections_safe_bisection_steps(
      bisection_steps,
    ),
  }
}

///|
pub fn ScreenSpaceReflections::with_use_secant(
  self : ScreenSpaceReflections,
  use_secant : Bool,
) -> ScreenSpaceReflections {
  ScreenSpaceReflections::{ ..self, use_secant, }
}

///|
pub let ecs_key_fxaa : @ecs.ComponentKey[Fxaa] = @ecs.register_component(
  debug_name="render3d.fxaa",
)

///|
pub let ecs_key_bloom : @ecs.ComponentKey[Bloom] = @ecs.register_component(
  debug_name="render3d.bloom",
)

///|
pub let ecs_key_custom_post_process3d : @ecs.ComponentKey[CustomPostProcess3d] = @ecs.register_component(
  debug_name="render3d.custom_post_process3d",
)

///|
pub let ecs_key_vignette : @ecs.ComponentKey[Vignette] = @post_process_effect_stack.ecs_key_vignette

///|
pub let ecs_key_motion_blur : @ecs.ComponentKey[MotionBlur] = @post_process_motion_blur.ecs_key_motion_blur

///|
pub let ecs_key_tonemapping : @ecs.ComponentKey[Tonemapping] = @ecs.register_component(
  debug_name="post_process.tonemapping",
)

///|
pub let ecs_key_color_grading : @ecs.ComponentKey[ColorGrading] = @ecs.register_component(
  debug_name="post_process.color_grading",
)

///|
pub let ecs_key_deband_dither : @ecs.ComponentKey[DebandDither] = @ecs.register_component(
  debug_name="post_process.deband_dither",
)

///|
pub let ecs_key_temporal_jitter : @ecs.ComponentKey[TemporalJitter] = @ecs.register_component(
  debug_name="render3d.temporal_jitter",
)

///|
pub let ecs_key_chromatic_aberration : @ecs.ComponentKey[ChromaticAberration] = @post_process_effect_stack.ecs_key_chromatic_aberration

///|
pub let ecs_key_temporal_anti_aliasing : @ecs.ComponentKey[TemporalAntiAliasing] = @ecs.register_component(
  debug_name="render3d.temporal_anti_aliasing",
)

///|
pub let ecs_key_screen_space_reflections : @ecs.ComponentKey[
  ScreenSpaceReflections,
] = @ecs.register_component(debug_name="render3d.screen_space_reflections")

///|
pub let ecs_key_screen_space_transmission : @ecs.ComponentKey[
  ScreenSpaceTransmission,
] = @pbr_transmission.ecs_key_screen_space_transmission

///|
pub let ecs_key_screen_space_ambient_occlusion : @ecs.ComponentKey[
  ScreenSpaceAmbientOcclusion,
] = @ecs.register_component(
  debug_name="render3d.screen_space_ambient_occlusion",
)

///|
pub impl @ecs.Component for Fxaa with component() {
  ecs_key_fxaa
}

///|
pub impl @ecs.Component for Bloom with component() {
  ecs_key_bloom
}

///|
pub impl @ecs.Component for CustomPostProcess3d with component() {
  ecs_key_custom_post_process3d
}

///|
pub impl @ecs.Component for Tonemapping with component() {
  ecs_key_tonemapping
}

///|
pub impl @ecs.Component for ColorGrading with component() {
  ecs_key_color_grading
}

///|
pub impl @ecs.Component for DebandDither with component() {
  ecs_key_deband_dither
}

///|
pub impl @ecs.Component for TemporalJitter with component() {
  ecs_key_temporal_jitter
}

///|
pub impl @ecs.Component for TemporalAntiAliasing with component() {
  ecs_key_temporal_anti_aliasing
}

///|
pub impl @ecs.Component for ScreenSpaceReflections with component() {
  ecs_key_screen_space_reflections
}

///|
pub impl @ecs.Component for ScreenSpaceAmbientOcclusion with component() {
  ecs_key_screen_space_ambient_occlusion
}
