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
fn color_grading_approx_eq(a : Float, b : Float) -> Bool {
  let delta = a - b
  if delta < 0.0F {
    -delta < 0.0001F
  } else {
    delta < 0.0001F
  }
}

///|
test "render3d: default color grading host uniform matches Bevy defaults" {
  let uniform = @render.host_color_grading_from_post_process(None)
  let ok = color_grading_approx_eq(uniform.balance_x_axis_x, 1.0F) &&
    color_grading_approx_eq(uniform.balance_x_axis_y, 0.0F) &&
    color_grading_approx_eq(uniform.balance_x_axis_z, 0.0F) &&
    color_grading_approx_eq(uniform.balance_y_axis_x, 0.0F) &&
    color_grading_approx_eq(uniform.balance_y_axis_y, 1.0F) &&
    color_grading_approx_eq(uniform.balance_y_axis_z, 0.0F) &&
    color_grading_approx_eq(uniform.balance_z_axis_x, 0.0F) &&
    color_grading_approx_eq(uniform.balance_z_axis_y, 0.0F) &&
    color_grading_approx_eq(uniform.balance_z_axis_z, 1.0F) &&
    color_grading_approx_eq(uniform.saturation_shadows, 1.0F) &&
    color_grading_approx_eq(uniform.saturation_midtones, 1.0F) &&
    color_grading_approx_eq(uniform.saturation_highlights, 1.0F) &&
    color_grading_approx_eq(uniform.contrast_shadows, 1.0F) &&
    color_grading_approx_eq(uniform.contrast_midtones, 1.0F) &&
    color_grading_approx_eq(uniform.contrast_highlights, 1.0F) &&
    color_grading_approx_eq(uniform.gamma_shadows, 1.0F) &&
    color_grading_approx_eq(uniform.gamma_midtones, 1.0F) &&
    color_grading_approx_eq(uniform.gamma_highlights, 1.0F) &&
    color_grading_approx_eq(uniform.gain_shadows, 1.0F) &&
    color_grading_approx_eq(uniform.gain_midtones, 1.0F) &&
    color_grading_approx_eq(uniform.gain_highlights, 1.0F) &&
    color_grading_approx_eq(uniform.lift_shadows, 0.0F) &&
    color_grading_approx_eq(uniform.lift_midtones, 0.0F) &&
    color_grading_approx_eq(uniform.lift_highlights, 0.0F) &&
    color_grading_approx_eq(uniform.midtones_start, 0.2F) &&
    color_grading_approx_eq(uniform.midtones_end, 0.7F) &&
    color_grading_approx_eq(uniform.exposure, 0.0F) &&
    color_grading_approx_eq(uniform.hue, 0.0F) &&
    color_grading_approx_eq(uniform.post_saturation, 1.0F)
  debug_inspect(ok, content="true")
}

///|
test "render3d: custom color grading host uniform preserves Bevy section values" {
  let global = ColorGradingGlobal::default()
  global.exposure = 1.25F
  global.temperature = 0.08F
  global.tint = -0.03F
  global.hue = 0.4F
  global.post_saturation = 1.6F
  global.midtones_range = { start: 0.15F, end_: 0.65F }
  let shadows = ColorGradingSection::default()
  shadows.saturation = 0.8F
  shadows.contrast = 1.1F
  shadows.gamma = 1.3F
  shadows.gain = 1.2F
  shadows.lift = -0.05F
  let midtones = ColorGradingSection::default()
  midtones.saturation = 1.2F
  midtones.contrast = 0.95F
  midtones.gamma = 0.9F
  midtones.gain = 1.05F
  midtones.lift = 0.02F
  let highlights = ColorGradingSection::default()
  highlights.saturation = 1.4F
  highlights.contrast = 1.25F
  highlights.gamma = 1.1F
  highlights.gain = 1.15F
  highlights.lift = 0.1F
  let grading = ColorGrading::default()
  grading.global = global
  grading.shadows = shadows
  grading.midtones = midtones
  grading.highlights = highlights
  let uniform = @render.host_color_grading_from_post_process(Some(grading))
  let ok = !color_grading_approx_eq(uniform.balance_x_axis_x, 1.0F) &&
    color_grading_approx_eq(uniform.saturation_shadows, 0.8F) &&
    color_grading_approx_eq(uniform.saturation_midtones, 1.2F) &&
    color_grading_approx_eq(uniform.saturation_highlights, 1.4F) &&
    color_grading_approx_eq(uniform.contrast_shadows, 1.1F) &&
    color_grading_approx_eq(uniform.contrast_midtones, 0.95F) &&
    color_grading_approx_eq(uniform.contrast_highlights, 1.25F) &&
    color_grading_approx_eq(uniform.gamma_shadows, 1.3F) &&
    color_grading_approx_eq(uniform.gamma_midtones, 0.9F) &&
    color_grading_approx_eq(uniform.gamma_highlights, 1.1F) &&
    color_grading_approx_eq(uniform.gain_shadows, 1.2F) &&
    color_grading_approx_eq(uniform.gain_midtones, 1.05F) &&
    color_grading_approx_eq(uniform.gain_highlights, 1.15F) &&
    color_grading_approx_eq(uniform.lift_shadows, -0.05F) &&
    color_grading_approx_eq(uniform.lift_midtones, 0.02F) &&
    color_grading_approx_eq(uniform.lift_highlights, 0.1F) &&
    color_grading_approx_eq(uniform.midtones_start, 0.15F) &&
    color_grading_approx_eq(uniform.midtones_end, 0.65F) &&
    color_grading_approx_eq(uniform.exposure, 1.25F) &&
    color_grading_approx_eq(uniform.hue, 0.4F) &&
    color_grading_approx_eq(uniform.post_saturation, 1.6F)
  debug_inspect(ok, content="true")
}

///|
test "render3d: direct color grading field mutation matches Bevy-style usage" {
  let grading = ColorGrading::default()
  grading.global.exposure = 0.75F
  grading.global.post_saturation = 1.4F
  grading.global.midtones_range = { start: 0.3F, end_: 0.6F }
  grading.midtones.gamma = 1.1F
  grading.highlights.gain = 1.25F
  let uniform = @render.host_color_grading_from_post_process(Some(grading))
  let ok = color_grading_approx_eq(uniform.exposure, 0.75F) &&
    color_grading_approx_eq(uniform.post_saturation, 1.4F) &&
    color_grading_approx_eq(uniform.midtones_start, 0.3F) &&
    color_grading_approx_eq(uniform.midtones_end, 0.6F) &&
    color_grading_approx_eq(uniform.gamma_midtones, 1.1F) &&
    color_grading_approx_eq(uniform.gain_highlights, 1.25F)
  debug_inspect(ok, content="true")
}

///|
test "render3d: color grading all_sections iterates in Bevy order" {
  let grading = ColorGrading::default()
  grading.shadows.gamma = 1.1F
  grading.midtones.gamma = 1.2F
  grading.highlights.gamma = 1.3F
  let values : Array[Float] = []
  for section in grading.all_sections() {
    values.push(section.gamma)
  }
  let ok = values.length() == 3 &&
    color_grading_approx_eq(values[0], 1.1F) &&
    color_grading_approx_eq(values[1], 1.2F) &&
    color_grading_approx_eq(values[2], 1.3F)
  debug_inspect(ok, content="true")
}

///|
test "render3d: color grading all_sections_mut updates original sections" {
  let grading = ColorGrading::default()
  for section in grading.all_sections_mut() {
    section.gamma = section.gamma + 0.5F
    section.saturation = section.saturation + 0.25F
  }
  let ok = color_grading_approx_eq(grading.shadows.gamma, 1.5F) &&
    color_grading_approx_eq(grading.midtones.gamma, 1.5F) &&
    color_grading_approx_eq(grading.highlights.gamma, 1.5F) &&
    color_grading_approx_eq(grading.shadows.saturation, 1.25F) &&
    color_grading_approx_eq(grading.midtones.saturation, 1.25F) &&
    color_grading_approx_eq(grading.highlights.saturation, 1.25F)
  debug_inspect(ok, content="true")
}

///|
test "render3d: color grading alone enables tonemap postprocess path" {
  let enabled = render3d_tonemapping_stage_enabled(
    None,
    None,
    false,
    Some(ColorGrading::default()),
  )
  debug_inspect(enabled, content="true")
}
