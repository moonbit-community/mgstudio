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
// Bevy source: `bevy/crates/bevy_math/src/curve/sample_curves.rs`.

///|
pub struct SampleCurve[T] {
  core : EvenCore[T]
  interpolation : (T, T, Float) -> T
}

///|
pub fn[T] SampleCurve::new(
  domain : Interval,
  samples : Array[T],
  interpolation : (T, T, Float) -> T,
) -> SampleCurve[T] raise EvenCoreError {
  let core = EvenCore::new(domain, samples)
  SampleCurve::{ core, interpolation }
}

///|
pub fn[T] SampleCurve::domain(self : SampleCurve[T]) -> Interval {
  self.core.domain()
}

///|
pub fn[T] SampleCurve::sample_unchecked(self : SampleCurve[T], t : Float) -> T {
  self.core.sample_with(t, self.interpolation)
}

///|
pub fn[T] SampleCurve::sample_clamped(self : SampleCurve[T], t : Float) -> T {
  self.sample_unchecked(self.domain().clamp(t))
}

///|
pub fn[T] SampleCurve::sample(self : SampleCurve[T], t : Float) -> T? {
  if self.domain().contains(t) {
    Some(self.sample_unchecked(t))
  } else {
    None
  }
}

///|
pub fn[T] SampleCurve::to_curve(self : SampleCurve[T]) -> Curve[T] {
  Curve::new(self.domain(), fn(t) { self.sample_unchecked(t) })
}

///|
pub struct SampleAutoCurve[T] {
  core : EvenCore[T]
}

///|
pub fn[T] SampleAutoCurve::new(
  domain : Interval,
  samples : Array[T],
) -> SampleAutoCurve[T] raise EvenCoreError {
  let core = EvenCore::new(domain, samples)
  SampleAutoCurve::{ core, }
}

///|
pub fn[T] SampleAutoCurve::domain(self : SampleAutoCurve[T]) -> Interval {
  self.core.domain()
}

///|
pub fn[T : @math.StableInterpolate] SampleAutoCurve::sample_unchecked(
  self : SampleAutoCurve[T],
  t : Float,
) -> T {
  self.core.sample_with(t, fn(lhs, rhs, s) { lhs.stable_interpolate(rhs, s) })
}

///|
pub fn[T : @math.StableInterpolate] SampleAutoCurve::sample_clamped(
  self : SampleAutoCurve[T],
  t : Float,
) -> T {
  self.sample_unchecked(self.domain().clamp(t))
}

///|
pub fn[T : @math.StableInterpolate] SampleAutoCurve::sample(
  self : SampleAutoCurve[T],
  t : Float,
) -> T? {
  if self.domain().contains(t) {
    Some(self.sample_unchecked(t))
  } else {
    None
  }
}

///|
pub fn[T : @math.StableInterpolate] SampleAutoCurve::to_curve(
  self : SampleAutoCurve[T],
) -> Curve[T] {
  Curve::new(self.domain(), fn(t) { self.sample_unchecked(t) })
}

///|
pub struct UnevenSampleCurve[T] {
  core : UnevenCore[T]
  interpolation : (T, T, Float) -> T
}

///|
pub fn[T] UnevenSampleCurve::new(
  sample_points : Array[(Float, T)],
  interpolation : (T, T, Float) -> T,
) -> UnevenSampleCurve[T] raise UnevenCoreError {
  let core = UnevenCore::new(sample_points)
  UnevenSampleCurve::{ core, interpolation }
}

///|
pub fn[T] UnevenSampleCurve::domain(self : UnevenSampleCurve[T]) -> Interval {
  self.core.domain()
}

///|
pub fn[T] UnevenSampleCurve::sample_unchecked(
  self : UnevenSampleCurve[T],
  t : Float,
) -> T {
  self.core.sample_with(t, self.interpolation)
}

///|
pub fn[T] UnevenSampleCurve::sample_clamped(
  self : UnevenSampleCurve[T],
  t : Float,
) -> T {
  self.sample_unchecked(self.domain().clamp(t))
}

///|
pub fn[T] UnevenSampleCurve::sample(
  self : UnevenSampleCurve[T],
  t : Float,
) -> T? {
  if self.domain().contains(t) {
    Some(self.sample_unchecked(t))
  } else {
    None
  }
}

///|
pub fn[T] UnevenSampleCurve::to_curve(self : UnevenSampleCurve[T]) -> Curve[T] {
  Curve::new(self.domain(), fn(t) { self.sample_unchecked(t) })
}

///|
pub fn[T] sample_curve(
  domain : Interval,
  samples : Array[T],
  interpolation : (T, T, Float) -> T,
) -> SampleCurve[T] raise EvenCoreError {
  SampleCurve::new(domain, samples, interpolation)
}

///|
pub fn[T] sample_auto_curve(
  domain : Interval,
  samples : Array[T],
) -> SampleAutoCurve[T] raise EvenCoreError {
  SampleAutoCurve::new(domain, samples)
}

///|
pub fn[T] uneven_sample_curve(
  sample_points : Array[(Float, T)],
  interpolation : (T, T, Float) -> T,
) -> UnevenSampleCurve[T] raise UnevenCoreError {
  UnevenSampleCurve::new(sample_points, interpolation)
}
