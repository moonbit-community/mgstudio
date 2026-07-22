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
// Bevy source: `bevy/crates/bevy_render/src/view/mod.rs::ColorGrading*`.

///|
const HOST_COLOR_GRADING_D65_X : Float = 0.31272F

///|
const HOST_COLOR_GRADING_D65_Y : Float = 0.32903F

///|
const HOST_COLOR_GRADING_D65_LMS_X : Float = 0.975538F

///|
const HOST_COLOR_GRADING_D65_LMS_Y : Float = 1.01648F

///|
const HOST_COLOR_GRADING_D65_LMS_Z : Float = 1.08475F

///|
/// Midtone range controls aligned with Bevy's `Range<f32>`-based surface.
pub(all) struct ColorGradingRange {
  mut start : Float
  mut end_ : Float
} derive(ToJson, FromJson)

///|
pub fn ColorGradingRange::ColorGradingRange() -> ColorGradingRange {
  { start: 0.2F, end_: 0.7F }
}

///|
fn color_grading_range_copy(value : ColorGradingRange) -> ColorGradingRange {
  let out = ColorGradingRange::ColorGradingRange()
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
pub fn ColorGradingGlobal::ColorGradingGlobal() -> ColorGradingGlobal {
  {
    exposure: 0.0F,
    temperature: 0.0F,
    tint: 0.0F,
    hue: 0.0F,
    post_saturation: 1.0F,
    midtones_range: ColorGradingRange(),
  }
}

///|
fn color_grading_global_copy(value : ColorGradingGlobal) -> ColorGradingGlobal {
  let out = ColorGradingGlobal::ColorGradingGlobal()
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
pub fn ColorGradingSection::ColorGradingSection() -> ColorGradingSection {
  { saturation: 1.0F, contrast: 1.0F, gamma: 1.0F, gain: 1.0F, lift: 0.0F }
}

///|
fn color_grading_section_copy(
  value : ColorGradingSection,
) -> ColorGradingSection {
  let out = ColorGradingSection::ColorGradingSection()
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
pub fn ColorGrading::ColorGrading() -> ColorGrading {
  {
    global: ColorGradingGlobal(),
    shadows: ColorGradingSection(),
    midtones: ColorGradingSection(),
    highlights: ColorGradingSection(),
  }
}

///|
pub fn ColorGrading::with_identical_sections(
  global : ColorGradingGlobal,
  section : ColorGradingSection,
) -> ColorGrading {
  let color_grading = ColorGrading::ColorGrading()
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
pub let ecs_key_color_grading : @ecs.ComponentKey[ColorGrading] = @ecs.register_component(
  debug_name="render.view.color_grading",
)

///|
pub impl @ecs.Component for ColorGrading with fn component() {
  ecs_key_color_grading
}

///|
fn host_color_grading_mat3_mul_vec3(
  x_axis : @math.Vec3,
  y_axis : @math.Vec3,
  z_axis : @math.Vec3,
  value : @math.Vec3,
) -> @math.Vec3 {
  x_axis
  .mul_scalar(value.x)
  .add(y_axis.mul_scalar(value.y))
  .add(z_axis.mul_scalar(value.z))
}

///|
pub fn host_color_grading_from_post_process(
  color_grading : ColorGrading?,
) -> HostColorGrading {
  let grading = match color_grading {
    Some(value) => value
    None => ColorGrading()
  }
  let white_point_x = HOST_COLOR_GRADING_D65_X - grading.global.temperature
  let white_point_y = HOST_COLOR_GRADING_D65_Y + grading.global.tint
  let white_point_lms = @math.Vec3::new(
    0.701634F + (-0.051461F + 0.452749F * white_point_x) / white_point_y,
    1.15856F + (0.045854F - 0.296122F * white_point_x) / white_point_y,
    -0.904175F + (0.953127F - 0.955206F * white_point_x) / white_point_y,
  )
  let white_point_adjustment = @math.Vec3::new(
    HOST_COLOR_GRADING_D65_LMS_X / white_point_lms.x,
    HOST_COLOR_GRADING_D65_LMS_Y / white_point_lms.y,
    HOST_COLOR_GRADING_D65_LMS_Z / white_point_lms.z,
  )
  let rgb_to_lms_x_axis = @math.Vec3::new(0.311692F, 0.0905138F, 0.00764433F)
  let rgb_to_lms_y_axis = @math.Vec3::new(0.652085F, 0.901341F, 0.0486554F)
  let rgb_to_lms_z_axis = @math.Vec3::new(0.0362225F, 0.00814478F, 0.943700F)
  let lms_to_rgb_x_axis = @math.Vec3::new(4.06305F, -0.40791F, -0.0118812F)
  let lms_to_rgb_y_axis = @math.Vec3::new(-2.93241F, 1.40437F, -0.0486532F)
  let lms_to_rgb_z_axis = @math.Vec3::new(-0.130646F, 0.00353630F, 1.0605344F)
  let scaled_rgb_to_lms_x_axis = @math.Vec3::new(
    rgb_to_lms_x_axis.x * white_point_adjustment.x,
    rgb_to_lms_x_axis.y * white_point_adjustment.y,
    rgb_to_lms_x_axis.z * white_point_adjustment.z,
  )
  let scaled_rgb_to_lms_y_axis = @math.Vec3::new(
    rgb_to_lms_y_axis.x * white_point_adjustment.x,
    rgb_to_lms_y_axis.y * white_point_adjustment.y,
    rgb_to_lms_y_axis.z * white_point_adjustment.z,
  )
  let scaled_rgb_to_lms_z_axis = @math.Vec3::new(
    rgb_to_lms_z_axis.x * white_point_adjustment.x,
    rgb_to_lms_z_axis.y * white_point_adjustment.y,
    rgb_to_lms_z_axis.z * white_point_adjustment.z,
  )
  let balance_x_axis = host_color_grading_mat3_mul_vec3(
    lms_to_rgb_x_axis, lms_to_rgb_y_axis, lms_to_rgb_z_axis, scaled_rgb_to_lms_x_axis,
  )
  let balance_y_axis = host_color_grading_mat3_mul_vec3(
    lms_to_rgb_x_axis, lms_to_rgb_y_axis, lms_to_rgb_z_axis, scaled_rgb_to_lms_y_axis,
  )
  let balance_z_axis = host_color_grading_mat3_mul_vec3(
    lms_to_rgb_x_axis, lms_to_rgb_y_axis, lms_to_rgb_z_axis, scaled_rgb_to_lms_z_axis,
  )
  let midtones_range = grading.global.midtones_range
  {
    balance_x_axis_x: balance_x_axis.x,
    balance_x_axis_y: balance_x_axis.y,
    balance_x_axis_z: balance_x_axis.z,
    balance_y_axis_x: balance_y_axis.x,
    balance_y_axis_y: balance_y_axis.y,
    balance_y_axis_z: balance_y_axis.z,
    balance_z_axis_x: balance_z_axis.x,
    balance_z_axis_y: balance_z_axis.y,
    balance_z_axis_z: balance_z_axis.z,
    saturation_shadows: grading.shadows.saturation,
    saturation_midtones: grading.midtones.saturation,
    saturation_highlights: grading.highlights.saturation,
    contrast_shadows: grading.shadows.contrast,
    contrast_midtones: grading.midtones.contrast,
    contrast_highlights: grading.highlights.contrast,
    gamma_shadows: grading.shadows.gamma,
    gamma_midtones: grading.midtones.gamma,
    gamma_highlights: grading.highlights.gamma,
    gain_shadows: grading.shadows.gain,
    gain_midtones: grading.midtones.gain,
    gain_highlights: grading.highlights.gain,
    lift_shadows: grading.shadows.lift,
    lift_midtones: grading.midtones.lift,
    lift_highlights: grading.highlights.lift,
    midtones_start: midtones_range.start,
    midtones_end: midtones_range.end_,
    exposure: grading.global.exposure,
    hue: grading.global.hue,
    post_saturation: grading.global.post_saturation,
  }
}
