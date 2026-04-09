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
// Bevy source: `bevy/crates/bevy_post_process/src/auto_exposure/compensation_curve.rs`.
// Curve sampling wrappers over `@pbr.AutoExposureCompensationCurve`.

///|
pub const AUTO_EXPOSURE_COMPENSATION_CURVE_LUT_SIZE : Int = 256

///|
pub fn auto_exposure_curve_extents(
  curve : AutoExposureCompensationCurve,
) -> (Float, Float, Float, Float) {
  (
    curve.min_log_lum,
    curve.max_log_lum,
    curve.min_compensation,
    curve.max_compensation,
  )
}

///|
pub fn auto_exposure_curve_sample(
  curve : AutoExposureCompensationCurve,
  log_luminance : Float,
) -> Float {
  let log_range = curve.max_log_lum - curve.min_log_lum
  if log_range <= 0.0F {
    return curve.min_compensation
  }
  let normalized = if log_luminance <= curve.min_log_lum {
    0.0F
  } else if log_luminance >= curve.max_log_lum {
    1.0F
  } else {
    (log_luminance - curve.min_log_lum) / log_range
  }
  let scaled_index = normalized *
    Float::from_double(
      (AUTO_EXPOSURE_COMPENSATION_CURVE_LUT_SIZE - 1).to_double(),
    )
  let index = scaled_index.floor().to_int()
  let lut_value = match curve.lut.get(index) {
    Some(value) => value.to_int()
    None => 0
  }
  let compensation_range = curve.max_compensation - curve.min_compensation
  if compensation_range <= 0.0F {
    curve.min_compensation
  } else {
    curve.min_compensation +
    Float::from_double(lut_value.to_double()) / 255.0F * compensation_range
  }
}
