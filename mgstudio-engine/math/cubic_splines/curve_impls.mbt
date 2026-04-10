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
pub using @math {type WithDerivative}

///|
pub using @math {type WithTwoDerivatives}

///|
pub fn[P : @math.SplinePoint] cubic_curve_sample_with_derivative(
  curve : @math.CubicCurve[P],
  t : Float,
) -> @math.WithDerivative[P] {
  curve.sample_with_derivative(t)
}

///|
pub fn[P : @math.SplinePoint] cubic_curve_sample_with_two_derivatives(
  curve : @math.CubicCurve[P],
  t : Float,
) -> @math.WithTwoDerivatives[P] {
  curve.sample_with_two_derivatives(t)
}

///|
pub fn[P : @math.SplinePoint] cubic_segment_sample_with_derivative(
  segment : @math.CubicSegment[P],
  t : Float,
) -> @math.WithDerivative[P] {
  segment.sample_with_derivative(t)
}

///|
pub fn[P : @math.SplinePoint] cubic_segment_sample_with_two_derivatives(
  segment : @math.CubicSegment[P],
  t : Float,
) -> @math.WithTwoDerivatives[P] {
  segment.sample_with_two_derivatives(t)
}
