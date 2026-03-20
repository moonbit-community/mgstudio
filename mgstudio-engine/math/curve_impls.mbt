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
pub fn[P] CubicSegment::domain(self : CubicSegment[P]) -> Interval {
  ignore(self)
  Interval::unit()
}

///|
pub fn[P : SplinePoint] CubicSegment::as_curve(
  self : CubicSegment[P],
) -> Curve[P] {
  Curve::new(Interval::unit(), fn(t) { self.position(t) })
}

///|
pub fn[P : SplinePoint] CubicSegment::sample_with_derivative(
  self : CubicSegment[P],
  t : Float,
) -> WithDerivative[P] {
  WithDerivative::{ value: self.position(t), derivative: self.velocity(t) }
}

///|
pub fn[P : SplinePoint] CubicSegment::sample_with_two_derivatives(
  self : CubicSegment[P],
  t : Float,
) -> WithTwoDerivatives[P] {
  WithTwoDerivatives::{
    value: self.position(t),
    derivative: self.velocity(t),
    second_derivative: self.acceleration(t),
  }
}

///|
pub fn[P] CubicCurve::domain(self : CubicCurve[P]) -> Interval {
  Interval::new(0.0F, Float::from_double(self.segments().length().to_double())).unwrap()
}

///|
pub fn[P : SplinePoint] CubicCurve::as_curve(self : CubicCurve[P]) -> Curve[P] {
  Curve::new(self.domain(), fn(t) { self.position(t) })
}

///|
pub fn[P : SplinePoint] CubicCurve::sample_with_derivative(
  self : CubicCurve[P],
  t : Float,
) -> WithDerivative[P] {
  WithDerivative::{ value: self.position(t), derivative: self.velocity(t) }
}

///|
pub fn[P : SplinePoint] CubicCurve::sample_with_two_derivatives(
  self : CubicCurve[P],
  t : Float,
) -> WithTwoDerivatives[P] {
  WithTwoDerivatives::{
    value: self.position(t),
    derivative: self.velocity(t),
    second_derivative: self.acceleration(t),
  }
}

///|
pub fn[T] EasingCurve::domain(self : EasingCurve[T]) -> Interval {
  ignore(self)
  Interval::unit()
}

///|
pub fn[T : Ease] EasingCurve::as_curve(self : EasingCurve[T]) -> Curve[T] {
  Curve::new(Interval::unit(), fn(t) { self.sample_clamped(t) })
}
