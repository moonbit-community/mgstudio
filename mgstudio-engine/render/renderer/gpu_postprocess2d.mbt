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
/// 2D post-process orchestration entry points.

///|
pub fn GpuBackend::draw_bloom2d(
  self : GpuBackend,
  scene_texture_id : Int,
  enabled : Int,
  intensity : Float,
  low_frequency_boost : Float,
  low_frequency_boost_curvature : Float,
  high_pass_frequency : Float,
  threshold : Float,
  threshold_softness : Float,
  composite_mode : Int,
  max_mip_dimension : Int,
  scale_x : Float,
  scale_y : Float,
  exposure : Float,
  tonemapping_mode : Int,
  deband_dither_enabled : Int,
  view_width : Int,
  view_height : Int,
  agx_lut_texture_id : Int,
  tony_lut_texture_id : Int,
  blender_lut_texture_id : Int,
  color_grading_balance_x_axis_x : Float,
  color_grading_balance_x_axis_y : Float,
  color_grading_balance_x_axis_z : Float,
  color_grading_balance_y_axis_x : Float,
  color_grading_balance_y_axis_y : Float,
  color_grading_balance_y_axis_z : Float,
  color_grading_balance_z_axis_x : Float,
  color_grading_balance_z_axis_y : Float,
  color_grading_balance_z_axis_z : Float,
  color_grading_saturation_shadows : Float,
  color_grading_saturation_midtones : Float,
  color_grading_saturation_highlights : Float,
  color_grading_contrast_shadows : Float,
  color_grading_contrast_midtones : Float,
  color_grading_contrast_highlights : Float,
  color_grading_gamma_shadows : Float,
  color_grading_gamma_midtones : Float,
  color_grading_gamma_highlights : Float,
  color_grading_gain_shadows : Float,
  color_grading_gain_midtones : Float,
  color_grading_gain_highlights : Float,
  color_grading_lift_shadows : Float,
  color_grading_lift_midtones : Float,
  color_grading_lift_highlights : Float,
  color_grading_midtones_start : Float,
  color_grading_midtones_end : Float,
  color_grading_exposure : Float,
  color_grading_hue : Float,
  color_grading_post_saturation : Float,
  fxaa_enabled : Int,
  fxaa_edge_threshold : Float,
  chromatic_aberration : Float,
  vignette : Float,
) -> Unit raise GpuBackendError {
  color_grading_balance_x_axis_x |> ignore
  color_grading_balance_x_axis_y |> ignore
  color_grading_balance_x_axis_z |> ignore
  color_grading_balance_y_axis_x |> ignore
  color_grading_balance_y_axis_y |> ignore
  color_grading_balance_y_axis_z |> ignore
  color_grading_balance_z_axis_x |> ignore
  color_grading_balance_z_axis_y |> ignore
  color_grading_balance_z_axis_z |> ignore
  color_grading_saturation_shadows |> ignore
  color_grading_saturation_midtones |> ignore
  color_grading_saturation_highlights |> ignore
  color_grading_contrast_shadows |> ignore
  color_grading_contrast_midtones |> ignore
  color_grading_contrast_highlights |> ignore
  color_grading_gamma_shadows |> ignore
  color_grading_gamma_midtones |> ignore
  color_grading_gamma_highlights |> ignore
  color_grading_gain_shadows |> ignore
  color_grading_gain_midtones |> ignore
  color_grading_gain_highlights |> ignore
  color_grading_lift_shadows |> ignore
  color_grading_lift_midtones |> ignore
  color_grading_lift_highlights |> ignore
  color_grading_midtones_start |> ignore
  color_grading_midtones_end |> ignore
  color_grading_exposure |> ignore
  color_grading_hue |> ignore
  color_grading_post_saturation |> ignore
  fxaa_enabled |> ignore
  fxaa_edge_threshold |> ignore
  chromatic_aberration |> ignore
  vignette |> ignore
  self.apply_bloom2d(
    scene_texture_id, enabled, intensity, low_frequency_boost, low_frequency_boost_curvature,
    high_pass_frequency, threshold, threshold_softness, composite_mode, max_mip_dimension,
    scale_x, scale_y, view_width, view_height,
  )
  self.draw_tonemapping2d(
    scene_texture_id, exposure, tonemapping_mode, deband_dither_enabled, view_width,
    view_height, agx_lut_texture_id, tony_lut_texture_id, blender_lut_texture_id,
  )
}

///|
pub fn draw_bloom2d(
  scene_texture_id~ : Int,
  enabled~ : Int,
  intensity~ : Float,
  low_frequency_boost~ : Float,
  low_frequency_boost_curvature~ : Float,
  high_pass_frequency~ : Float,
  threshold~ : Float,
  threshold_softness~ : Float,
  composite_mode~ : Int,
  max_mip_dimension~ : Int,
  scale_x~ : Float,
  scale_y~ : Float,
  exposure~ : Float,
  tonemapping_mode~ : Int,
  deband_dither_enabled~ : Int,
  fxaa_enabled~ : Int,
  fxaa_edge_threshold~ : Float,
  fxaa_edge_threshold_min~ : Float,
  chromatic_aberration_intensity~ : Float,
  chromatic_aberration_max_samples~ : Int,
  vignette_intensity~ : Float,
  vignette_radius~ : Float,
  vignette_smoothness~ : Float,
  vignette_roundness~ : Float,
  vignette_center_x~ : Float,
  vignette_center_y~ : Float,
  vignette_edge_compensation~ : Float,
  vignette_color_r~ : Float,
  vignette_color_g~ : Float,
  vignette_color_b~ : Float,
  vignette_color_a~ : Float,
  view_width~ : Int,
  view_height~ : Int,
  agx_lut_texture_id~ : Int,
  tony_lut_texture_id~ : Int,
  blender_lut_texture_id~ : Int,
  color_grading_balance_x_axis_x~ : Float,
  color_grading_balance_x_axis_y~ : Float,
  color_grading_balance_x_axis_z~ : Float,
  color_grading_balance_y_axis_x~ : Float,
  color_grading_balance_y_axis_y~ : Float,
  color_grading_balance_y_axis_z~ : Float,
  color_grading_balance_z_axis_x~ : Float,
  color_grading_balance_z_axis_y~ : Float,
  color_grading_balance_z_axis_z~ : Float,
  color_grading_saturation_shadows~ : Float,
  color_grading_saturation_midtones~ : Float,
  color_grading_saturation_highlights~ : Float,
  color_grading_contrast_shadows~ : Float,
  color_grading_contrast_midtones~ : Float,
  color_grading_contrast_highlights~ : Float,
  color_grading_gamma_shadows~ : Float,
  color_grading_gamma_midtones~ : Float,
  color_grading_gamma_highlights~ : Float,
  color_grading_gain_shadows~ : Float,
  color_grading_gain_midtones~ : Float,
  color_grading_gain_highlights~ : Float,
  color_grading_lift_shadows~ : Float,
  color_grading_lift_midtones~ : Float,
  color_grading_lift_highlights~ : Float,
  color_grading_midtones_start~ : Float,
  color_grading_midtones_end~ : Float,
  color_grading_exposure~ : Float,
  color_grading_hue~ : Float,
  color_grading_post_saturation~ : Float,
) -> Unit {
  let fxaa_edge_threshold_value = if fxaa_edge_threshold <
    fxaa_edge_threshold_min {
    fxaa_edge_threshold_min
  } else {
    fxaa_edge_threshold
  }
  let chromatic_aberration_value = chromatic_aberration_intensity
  let vignette_value = vignette_intensity
  chromatic_aberration_max_samples |> ignore
  vignette_radius |> ignore
  vignette_smoothness |> ignore
  vignette_roundness |> ignore
  vignette_center_x |> ignore
  vignette_center_y |> ignore
  vignette_edge_compensation |> ignore
  vignette_color_r |> ignore
  vignette_color_g |> ignore
  vignette_color_b |> ignore
  vignette_color_a |> ignore
  if ensure_backend() is Some(backend) {
    backend.draw_bloom2d(
      scene_texture_id, enabled, intensity, low_frequency_boost, low_frequency_boost_curvature,
      high_pass_frequency, threshold, threshold_softness, composite_mode, max_mip_dimension,
      scale_x, scale_y, exposure, tonemapping_mode, deband_dither_enabled, view_width,
      view_height, agx_lut_texture_id, tony_lut_texture_id, blender_lut_texture_id,
      color_grading_balance_x_axis_x, color_grading_balance_x_axis_y, color_grading_balance_x_axis_z,
      color_grading_balance_y_axis_x, color_grading_balance_y_axis_y, color_grading_balance_y_axis_z,
      color_grading_balance_z_axis_x, color_grading_balance_z_axis_y, color_grading_balance_z_axis_z,
      color_grading_saturation_shadows, color_grading_saturation_midtones, color_grading_saturation_highlights,
      color_grading_contrast_shadows, color_grading_contrast_midtones, color_grading_contrast_highlights,
      color_grading_gamma_shadows, color_grading_gamma_midtones, color_grading_gamma_highlights,
      color_grading_gain_shadows, color_grading_gain_midtones, color_grading_gain_highlights,
      color_grading_lift_shadows, color_grading_lift_midtones, color_grading_lift_highlights,
      color_grading_midtones_start, color_grading_midtones_end, color_grading_exposure,
      color_grading_hue, color_grading_post_saturation, fxaa_enabled, fxaa_edge_threshold_value,
      chromatic_aberration_value, vignette_value,
    ) catch {
      err => debug_runtime_error("draw_bloom2d", err)
    }
  }
}
