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
const AUTO_EXPOSURE_COMPENSATION_CURVE_LUT_SIZE : Int = 256

///|
pub(all) suberror AutoExposureCompensationCurveError {
  InvalidCurve
  DiscontinuityFound
  NotMonotonic
}

///|
pub(open) trait AutoExposureCompensationCurveSource {
  to_auto_exposure_curve(self : Self) -> @math.CubicCurve[@math.Vec2] raise @math.InsufficientDataError
}

///|
pub impl AutoExposureCompensationCurveSource for @math.LinearSpline[@math.Vec2] with to_auto_exposure_curve(
  self,
) {
  self.to_curve()
}

///|
pub impl AutoExposureCompensationCurveSource for @math.CubicCurve[@math.Vec2] with to_auto_exposure_curve(
  self,
) {
  self
}

///|
pub struct AutoExposureCompensationCurve {
  min_log_lum : Float
  max_log_lum : Float
  min_compensation : Float
  max_compensation : Float
  lut : Bytes
}

///|
pub fn AutoExposureCompensationCurve::default() -> AutoExposureCompensationCurve {
  AutoExposureCompensationCurve::{
    min_log_lum: 0.0F,
    max_log_lum: 0.0F,
    min_compensation: 0.0F,
    max_compensation: 0.0F,
    lut: Bytes::makei(AUTO_EXPOSURE_COMPENSATION_CURVE_LUT_SIZE, _ => 0),
  }
}

///|
pub fn[T : AutoExposureCompensationCurveSource] AutoExposureCompensationCurve::from_curve(
  curve : T,
) -> AutoExposureCompensationCurve raise AutoExposureCompensationCurveError {
  let curve_value = curve.to_auto_exposure_curve() catch {
    _ => raise InvalidCurve
  }
  if curve_value.segments().length() == 0 {
    raise InvalidCurve
  }
  let min_log_lum = curve_value.position(0.0F).x
  let max_log_lum = curve_value.position(
      Float::from_double(curve_value.segments().length().to_double()),
    ).x
  let log_lum_range = max_log_lum - min_log_lum
  if log_lum_range <= 0.0F {
    raise NotMonotonic
  }
  let lut_values : Array[Float] = []
  for _ in 0..<AUTO_EXPOSURE_COMPENSATION_CURVE_LUT_SIZE {
    lut_values.push(0.0F)
  }
  let mut previous = curve_value.position(0.0F)
  let mut min_compensation = previous.y
  let mut max_compensation = previous.y
  for segment in curve_value.segments() {
    if !auto_exposure_curve_vec2_eq(segment.position(0.0F), previous) {
      raise DiscontinuityFound
    }
    for sample_index in 1..<64 {
      let current = segment.position(
        Float::from_double(sample_index.to_double()) / 63.0F,
      )
      if current.x < previous.x {
        raise NotMonotonic
      }
      let lut_begin = (previous.x - min_log_lum) /
        log_lum_range *
        Float::from_double(
          (AUTO_EXPOSURE_COMPENSATION_CURVE_LUT_SIZE - 1).to_double(),
        )
      let lut_end = (current.x - min_log_lum) /
        log_lum_range *
        Float::from_double(
          (AUTO_EXPOSURE_COMPENSATION_CURVE_LUT_SIZE - 1).to_double(),
        )
      let lut_inv_range = if lut_end == lut_begin {
        0.0F
      } else {
        1.0F / (lut_end - lut_begin)
      }
      let lut_begin_index = auto_exposure_curve_ceil_to_index(lut_begin)
      let lut_end_index = auto_exposure_curve_floor_to_index(lut_end)
      if lut_end_index >= lut_begin_index {
        for lut_index in lut_begin_index..<(lut_end_index + 1) {
          let t = if lut_inv_range == 0.0F {
            0.0F
          } else {
            (Float::from_double(lut_index.to_double()) - lut_begin) *
            lut_inv_range
          }
          let value = auto_exposure_curve_lerp(previous.y, current.y, t)
          lut_values[lut_index] = value
          if value < min_compensation {
            min_compensation = value
          }
          if value > max_compensation {
            max_compensation = value
          }
        }
      }
      previous = current
    }
  }
  let compensation_range = max_compensation - min_compensation
  let lut = if compensation_range > 0.0F {
    Bytes::makei(AUTO_EXPOSURE_COMPENSATION_CURVE_LUT_SIZE, index => {
      let normalized = (lut_values[index] - min_compensation) *
        255.0F /
        compensation_range
      auto_exposure_curve_float_to_byte(normalized)
    })
  } else {
    Bytes::makei(AUTO_EXPOSURE_COMPENSATION_CURVE_LUT_SIZE, _ => 0)
  }
  AutoExposureCompensationCurve::{
    min_log_lum,
    max_log_lum,
    min_compensation,
    max_compensation,
    lut,
  }
}

///|
fn auto_exposure_curve_vec2_eq(lhs : @math.Vec2, rhs : @math.Vec2) -> Bool {
  (lhs.x - rhs.x).abs() <= 0.000001F && (lhs.y - rhs.y).abs() <= 0.000001F
}

///|
fn auto_exposure_curve_lerp(start : Float, end_ : Float, t : Float) -> Float {
  start + (end_ - start) * t
}

///|
fn auto_exposure_curve_floor_to_index(value : Float) -> Int {
  auto_exposure_curve_clamp_index(@float.floor(value).to_double().to_int())
}

///|
fn auto_exposure_curve_ceil_to_index(value : Float) -> Int {
  auto_exposure_curve_clamp_index(@float.ceil(value).to_double().to_int())
}

///|
fn auto_exposure_curve_clamp_index(value : Int) -> Int {
  if value < 0 {
    0
  } else if value >= AUTO_EXPOSURE_COMPENSATION_CURVE_LUT_SIZE {
    AUTO_EXPOSURE_COMPENSATION_CURVE_LUT_SIZE - 1
  } else {
    value
  }
}

///|
fn auto_exposure_curve_float_to_byte(value : Float) -> Byte {
  let clamped = if value < 0.0F {
    0.0F
  } else if value > 255.0F {
    255.0F
  } else {
    value
  }
  clamped.to_double().to_int().to_byte()
}
