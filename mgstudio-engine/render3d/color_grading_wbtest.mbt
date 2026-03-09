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
  let uniform = render3d_color_grading_host_uniform(None)
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
  inspect(ok, content="true")
}

///|
test "render3d: custom color grading host uniform preserves Bevy section values" {
  let global = ColorGradingGlobal::default()
    .with_exposure(1.25F)
    .with_temperature(0.08F)
    .with_tint(-0.03F)
    .with_hue(0.4F)
    .with_post_saturation(1.6F)
    .with_midtones_range(0.15F, 0.65F)
  let shadows = ColorGradingSection::default()
    .with_saturation(0.8F)
    .with_contrast(1.1F)
    .with_gamma(1.3F)
    .with_gain(1.2F)
    .with_lift(-0.05F)
  let midtones = ColorGradingSection::default()
    .with_saturation(1.2F)
    .with_contrast(0.95F)
    .with_gamma(0.9F)
    .with_gain(1.05F)
    .with_lift(0.02F)
  let highlights = ColorGradingSection::default()
    .with_saturation(1.4F)
    .with_contrast(1.25F)
    .with_gamma(1.1F)
    .with_gain(1.15F)
    .with_lift(0.1F)
  let grading = ColorGrading::new(
    global,
    ColorGradingSettings::default()
    .with_shadows(shadows)
    .with_midtones(midtones)
    .with_highlights(highlights),
  )
  let uniform = render3d_color_grading_host_uniform(Some(grading))
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
  inspect(ok, content="true")
}

///|
test "render3d: color grading alone enables tonemap postprocess path" {
  let enabled = render3d_tonemap_postprocess_enabled(
    None,
    None,
    false,
    Some(ColorGrading::default()),
    None,
    None,
    None,
  )
  inspect(enabled, content="true")
}
