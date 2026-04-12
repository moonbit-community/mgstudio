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
// Bevy source: `bevy/crates/bevy_math/src/cubic_splines/curve_impls.rs`.

///|
pub struct WithDerivative[P] {
  value : P
  derivative : P
}

///|
pub struct WithTwoDerivatives[P] {
  value : P
  derivative : P
  second_derivative : P
}

///|
pub fn[P : @math.SplinePoint] cubic_curve_sample_with_derivative(
  curve : CubicCurve[P],
  t : Float,
) -> WithDerivative[P] {
  WithDerivative::{ value: curve.position(t), derivative: curve.velocity(t) }
}

///|
pub fn[P : @math.SplinePoint] cubic_curve_sample_with_two_derivatives(
  curve : CubicCurve[P],
  t : Float,
) -> WithTwoDerivatives[P] {
  WithTwoDerivatives::{
    value: curve.position(t),
    derivative: curve.velocity(t),
    second_derivative: curve.acceleration(t),
  }
}

///|
pub fn[P : @math.SplinePoint] cubic_segment_sample_with_derivative(
  segment : CubicSegment[P],
  t : Float,
) -> WithDerivative[P] {
  WithDerivative::{ value: segment.position(t), derivative: segment.velocity(t) }
}

///|
pub fn[P : @math.SplinePoint] cubic_segment_sample_with_two_derivatives(
  segment : CubicSegment[P],
  t : Float,
) -> WithTwoDerivatives[P] {
  WithTwoDerivatives::{
    value: segment.position(t),
    derivative: segment.velocity(t),
    second_derivative: segment.acceleration(t),
  }
}
