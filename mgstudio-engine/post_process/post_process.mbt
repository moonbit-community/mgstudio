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
  High
}

///|
pub fn FxaaSensitivity::get_str(self : FxaaSensitivity) -> String {
  match self {
    Low => "LOW"
    Medium => "MEDIUM"
    High => "HIGH"
    Ultra => "ULTRA"
    Extreme => "EXTREME"
  }
}

///|
/// Camera post-process settings aligned with Bevy's `Fxaa`.
pub struct Fxaa {
  enabled : Bool
  edge_threshold : FxaaSensitivity
  edge_threshold_min : FxaaSensitivity
} derive(ToJson, FromJson)

///|
pub fn Fxaa::Fxaa() -> Fxaa {
  { enabled: true, edge_threshold: High, edge_threshold_min: High }
}

///|
pub fn Fxaa::new(enabled : Bool) -> Fxaa {
  { ..Fxaa(), enabled, }
}

///|
pub fn Fxaa::new_with_sensitivity(
  enabled : Bool,
  edge_threshold : FxaaSensitivity,
  edge_threshold_min : FxaaSensitivity,
) -> Fxaa {
  { enabled, edge_threshold, edge_threshold_min }
}

///|
pub fn Fxaa::with_enabled(self : Fxaa, enabled : Bool) -> Fxaa {
  { ..self, enabled, }
}

///|
pub fn Fxaa::with_edge_threshold(
  self : Fxaa,
  edge_threshold : FxaaSensitivity,
) -> Fxaa {
  { ..self, edge_threshold, }
}

///|
pub fn Fxaa::with_edge_threshold_min(
  self : Fxaa,
  edge_threshold_min : FxaaSensitivity,
) -> Fxaa {
  { ..self, edge_threshold_min, }
}

///|
pub fn Fxaa::with_sensitivity(
  self : Fxaa,
  sensitivity : FxaaSensitivity,
) -> Fxaa {
  { ..self, edge_threshold: sensitivity, edge_threshold_min: sensitivity }
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
pub fn CustomPostProcess3d::CustomPostProcess3d() -> CustomPostProcess3d {
  {
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
  { ..CustomPostProcess3d(), shader_path, }
}

///|
pub fn CustomPostProcess3d::with_enabled(
  self : CustomPostProcess3d,
  enabled : Bool,
) -> CustomPostProcess3d {
  { ..self, enabled, }
}

///|
pub fn CustomPostProcess3d::with_shader_path(
  self : CustomPostProcess3d,
  shader_path : String,
) -> CustomPostProcess3d {
  { ..self, shader_path, }
}

///|
pub fn CustomPostProcess3d::with_fragment_entry(
  self : CustomPostProcess3d,
  fragment_entry : String,
) -> CustomPostProcess3d {
  { ..self, fragment_entry, }
}

///|
pub fn CustomPostProcess3d::with_uniform(
  self : CustomPostProcess3d,
  uniform_x : Float,
  uniform_y : Float,
  uniform_z : Float,
  uniform_w : Float,
) -> CustomPostProcess3d {
  { ..self, uniform_x, uniform_y, uniform_z, uniform_w }
}

///|
pub fn CustomPostProcess3d::with_intensity(
  self : CustomPostProcess3d,
  intensity : Float,
) -> CustomPostProcess3d {
  { ..self, uniform_x: intensity }
}

///|
/// Camera temporal AA settings aligned with Bevy's `TemporalAntiAliasing`.
pub struct TemporalAntiAliasing {
  reset : Bool
} derive(ToJson, FromJson)

///|
pub fn TemporalAntiAliasing::TemporalAntiAliasing() -> TemporalAntiAliasing {
  { reset: true }
}

///|
pub fn TemporalAntiAliasing::new(reset : Bool) -> TemporalAntiAliasing {
  { reset, }
}

///|
pub fn TemporalAntiAliasing::with_reset(
  self : TemporalAntiAliasing,
  reset : Bool,
) -> TemporalAntiAliasing {
  if self.reset == reset {
    self
  } else {
    { reset, }
  }
}

///|
/// Camera mip bias applied when sampling material textures.
///
/// This mirrors Bevy's `bevy_render::camera::MipBias` and is commonly
/// required by temporal antialiasing to reduce texture blur.
pub struct MipBias {
  bias : Float
} derive(Eq, ToJson, FromJson)

///|
pub fn MipBias::MipBias() -> MipBias {
  { bias: -1.0F }
}

///|
pub fn MipBias::new(bias : Float) -> MipBias {
  { bias, }
}

///|
pub fn MipBias::value(self : MipBias) -> Float {
  self.bias
}

///|
pub fn MipBias::with_bias(self : MipBias, bias : Float) -> MipBias {
  if self.bias == bias {
    self
  } else {
    { bias, }
  }
}

///|
// Bevy source: `bevy/crates/bevy_render/src/camera.rs` owns `TemporalJitter`;
// re-exported here for the post-process consumers.
pub type TemporalJitter = @render.TemporalJitter

///|
pub type ColorGradingRange = @render.ColorGradingRange

///|
pub type ColorGradingGlobal = @render.ColorGradingGlobal

///|
pub type ColorGradingSection = @render.ColorGradingSection

///|
pub type ColorGrading = @render.ColorGrading

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
  PbrNeutral
} derive(Eq, Hash, Debug, ToJson, FromJson)

///|
pub fn Tonemapping::default() -> Tonemapping {
  TonyMcMapface
}

///|
/// Enables / disables screen-space deband dithering in the tonemapping pass.
pub(all) enum DebandDither {
  Disabled
  Enabled
} derive(Eq, Debug, ToJson, FromJson)

///|
pub fn DebandDither::default() -> DebandDither {
  Disabled
}

///|
pub type BloomPrefilter = @post_process_bloom.BloomPrefilter

///|
pub type BloomCompositeMode = @post_process_bloom.BloomCompositeMode

///|
pub type Bloom = @post_process_bloom.Bloom

///|
pub(all) enum ScreenSpaceAmbientOcclusionQualityLevel {
  Low
  Medium
  High
  Ultra
  Custom(Int, Int)
} derive(Eq, Debug, ToJson, FromJson)

///|
pub fn ScreenSpaceAmbientOcclusionQualityLevel::default() -> ScreenSpaceAmbientOcclusionQualityLevel {
  High
}

///|
/// Camera ambient occlusion settings aligned with Bevy's
/// `ScreenSpaceAmbientOcclusion`.
pub struct ScreenSpaceAmbientOcclusion {
  quality_level : ScreenSpaceAmbientOcclusionQualityLevel
  constant_object_thickness : Float
} derive(ToJson, FromJson)

///|
pub fn ScreenSpaceAmbientOcclusion::ScreenSpaceAmbientOcclusion() -> ScreenSpaceAmbientOcclusion {
  {
    quality_level: ScreenSpaceAmbientOcclusionQualityLevel::default(),
    constant_object_thickness: 0.25F,
  }
}

///|
pub fn ScreenSpaceAmbientOcclusion::with_quality_level(
  self : ScreenSpaceAmbientOcclusion,
  quality_level : ScreenSpaceAmbientOcclusionQualityLevel,
) -> ScreenSpaceAmbientOcclusion {
  { ..self, quality_level, }
}

///|
pub fn ScreenSpaceAmbientOcclusion::with_constant_object_thickness(
  self : ScreenSpaceAmbientOcclusion,
  constant_object_thickness : Float,
) -> ScreenSpaceAmbientOcclusion {
  {
    ..self,
    constant_object_thickness: if constant_object_thickness < 0.0F {
      0.0F
    } else {
      constant_object_thickness
    },
  }
}

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
pub fn ScreenSpaceReflections::ScreenSpaceReflections() -> ScreenSpaceReflections {
  let (min_start, min_end) = screen_space_reflections_safe_range(0.08F, 0.12F)
  let (max_start, max_end) = screen_space_reflections_safe_range(0.55F, 0.6F)
  let (edge_start, edge_end) = screen_space_reflections_safe_range(0.0F, 0.0F)
  {
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
  {
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
  {
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
  { ..self, edge_fadeout_start: safe_start, edge_fadeout_end: safe_end }
}

///|
pub fn ScreenSpaceReflections::with_thickness(
  self : ScreenSpaceReflections,
  thickness : Float,
) -> ScreenSpaceReflections {
  { ..self, thickness: screen_space_reflections_safe_thickness(thickness) }
}

///|
pub fn ScreenSpaceReflections::with_linear_steps(
  self : ScreenSpaceReflections,
  linear_steps : Int,
) -> ScreenSpaceReflections {
  {
    ..self,
    linear_steps: screen_space_reflections_safe_linear_steps(linear_steps),
  }
}

///|
pub fn ScreenSpaceReflections::with_linear_march_exponent(
  self : ScreenSpaceReflections,
  linear_march_exponent : Float,
) -> ScreenSpaceReflections {
  {
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
  {
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
  { ..self, use_secant, }
}

///|
pub let ecs_key_fxaa : @ecs.ComponentKey[Fxaa] = @ecs.register_component(
  debug_name="render3d.fxaa",
)

///|
pub let ecs_key_bloom : @ecs.ComponentKey[Bloom] = @post_process_bloom.ecs_key_bloom

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
pub let ecs_key_color_grading : @ecs.ComponentKey[ColorGrading] = @render.ecs_key_color_grading

///|
pub let ecs_key_deband_dither : @ecs.ComponentKey[DebandDither] = @ecs.register_component(
  debug_name="post_process.deband_dither",
)

///|
pub let ecs_key_temporal_jitter : @ecs.ComponentKey[TemporalJitter] = @render.ecs_key_temporal_jitter

///|
pub let ecs_key_mip_bias : @ecs.ComponentKey[MipBias] = @ecs.register_component(
  debug_name="render3d.mip_bias",
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
pub let ecs_key_screen_space_ambient_occlusion : @ecs.ComponentKey[
  ScreenSpaceAmbientOcclusion,
] = @ecs.register_component(
  debug_name="render3d.screen_space_ambient_occlusion",
)

///|
pub impl @ecs.Component for Fxaa with fn component() {
  ecs_key_fxaa
}

///|
pub impl @ecs.Component for CustomPostProcess3d with fn component() {
  ecs_key_custom_post_process3d
}

///|
pub impl @ecs.Component for Tonemapping with fn component() {
  ecs_key_tonemapping
}

///|
pub impl @ecs.Component for DebandDither with fn component() {
  ecs_key_deband_dither
}

///|
pub impl @ecs.Component for MipBias with fn component() {
  ecs_key_mip_bias
}

///|
pub impl @ecs.Component for TemporalAntiAliasing with fn component() {
  ecs_key_temporal_anti_aliasing
}

///|
pub impl @ecs.Component for ScreenSpaceReflections with fn component() {
  ecs_key_screen_space_reflections
}

///|
pub impl @ecs.Component for ScreenSpaceAmbientOcclusion with fn component() {
  ecs_key_screen_space_ambient_occlusion
}
