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
// Bevy source: `bevy/crates/bevy_post_process/src/auto_exposure/pipeline.rs`.
// Host-side compute pass metadata derived from the existing auto exposure runtime.

///|
pub const AUTO_EXPOSURE_HISTOGRAM_BIN_COUNT : Int = 64

///|
pub const AUTO_EXPOSURE_HISTOGRAM_WORKGROUP_SIZE : Int = 16

///|
pub enum AutoExposurePass {
  Histogram
  Average
} derive(Eq, Debug)

///|
pub struct AutoExposurePipeline {
  histogram_bin_count : Int
  histogram_workgroup_size : Int
} derive(ToJson, FromJson)

///|
pub fn AutoExposurePipeline::default() -> AutoExposurePipeline {
  AutoExposurePipeline::{
    histogram_bin_count: AUTO_EXPOSURE_HISTOGRAM_BIN_COUNT,
    histogram_workgroup_size: AUTO_EXPOSURE_HISTOGRAM_WORKGROUP_SIZE,
  }
}

///|
pub fn AutoExposurePipeline::new(
  histogram_bin_count : Int,
  histogram_workgroup_size : Int,
) -> AutoExposurePipeline {
  let safe_bin_count = if histogram_bin_count <= 0 {
    AUTO_EXPOSURE_HISTOGRAM_BIN_COUNT
  } else {
    histogram_bin_count
  }
  let safe_workgroup_size = if histogram_workgroup_size <= 0 {
    AUTO_EXPOSURE_HISTOGRAM_WORKGROUP_SIZE
  } else {
    histogram_workgroup_size
  }
  AutoExposurePipeline::{
    histogram_bin_count: safe_bin_count,
    histogram_workgroup_size: safe_workgroup_size,
  }
}

///|
pub struct AutoExposureUniform {
  min_ev100 : Float
  max_ev100 : Float
  low_percent : Float
  high_percent : Float
  speed_brighten : Float
  speed_darken : Float
  exponential_transition_distance : Float
  viewport_width : Int
  viewport_height : Int
  histogram_bin_count : Int
  curve_min_log_lum : Float
  curve_max_log_lum : Float
  curve_min_compensation : Float
  curve_max_compensation : Float
} derive(ToJson, FromJson)

///|
pub fn auto_exposure_pipeline_passes() -> Array[AutoExposurePass] {
  [Histogram, Average]
}

///|
pub fn auto_exposure_histogram_workgroups(
  pipeline : AutoExposurePipeline,
  viewport_width : Int,
  viewport_height : Int,
) -> (Int, Int) {
  let width = if viewport_width <= 0 { 1 } else { viewport_width }
  let height = if viewport_height <= 0 { 1 } else { viewport_height }
  let workgroup = pipeline.histogram_workgroup_size
  let groups_x = (width + workgroup - 1) / workgroup
  let groups_y = (height + workgroup - 1) / workgroup
  (groups_x, groups_y)
}

///|
pub fn auto_exposure_uniform(
  settings : AutoExposure,
  curve : AutoExposureCompensationCurve?,
  pipeline : AutoExposurePipeline,
  viewport_width : Int,
  viewport_height : Int,
) -> AutoExposureUniform {
  let extents = match curve {
    Some(curve_value) => auto_exposure_curve_extents(curve_value)
    None => (0.0F, 0.0F, 0.0F, 0.0F)
  }
  AutoExposureUniform::{
    min_ev100: settings.min_ev100,
    max_ev100: settings.max_ev100,
    low_percent: settings.low_percent,
    high_percent: settings.high_percent,
    speed_brighten: settings.speed_brighten,
    speed_darken: settings.speed_darken,
    exponential_transition_distance: settings.exponential_transition_distance,
    viewport_width,
    viewport_height,
    histogram_bin_count: pipeline.histogram_bin_count,
    curve_min_log_lum: extents.0,
    curve_max_log_lum: extents.1,
    curve_min_compensation: extents.2,
    curve_max_compensation: extents.3,
  }
}
