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
// Bevy source: `bevy/crates/bevy_math/src/curve/cores.rs`.

///|
pub(all) enum InterpolationDatum[T] {
  Exact(T)
  LeftTail(T)
  RightTail(T)
  Between(T, T, Float)
}

///|
pub fn[T, S] InterpolationDatum::map(
  self : InterpolationDatum[T],
  f : (T) -> S,
) -> InterpolationDatum[S] {
  match self {
    Exact(value) => Exact(f(value))
    LeftTail(value) => LeftTail(f(value))
    RightTail(value) => RightTail(f(value))
    Between(lhs, rhs, t) => Between(f(lhs), f(rhs), t)
  }
}

///|
pub(all) suberror EvenCoreError {
  NotEnoughSamples(Int)
  UnboundedDomain
}

///|
pub(all) suberror UnevenCoreError {
  NotEnoughSamples(Int)
  NonFiniteSampleTime
  NonIncreasingSampleTimes
}

///|
pub struct EvenCore[T] {
  domain_ : @math.Interval
  samples : Array[T]
}

///|
pub fn[T] EvenCore::new(
  domain : @math.Interval,
  samples : Array[T],
) -> EvenCore[T] raise EvenCoreError {
  if samples.length() < 2 {
    raise NotEnoughSamples(samples.length())
  }
  if !domain.is_bounded() {
    raise UnboundedDomain
  }
  EvenCore::{ domain_: domain, samples }
}

///|
pub fn[T] EvenCore::domain(self : EvenCore[T]) -> @math.Interval {
  self.domain_
}

///|
pub fn[T] EvenCore::sample_with(
  self : EvenCore[T],
  t : Float,
  interpolation : (T, T, Float) -> T,
) -> T {
  match even_interp(self.domain_, self.samples.length(), t) {
    Exact(index) => self.samples[index]
    LeftTail(index) => self.samples[index]
    RightTail(index) => self.samples[index]
    Between(lower, upper, s) =>
      interpolation(self.samples[lower], self.samples[upper], s)
  }
}

///|
pub fn[T] EvenCore::sample_interp(
  self : EvenCore[T],
  t : Float,
) -> InterpolationDatum[T] {
  even_interp(self.domain_, self.samples.length(), t).map(fn(index) {
    self.samples[index]
  })
}

///|
pub fn even_interp(
  domain : @math.Interval,
  sample_count : Int,
  t : Float,
) -> InterpolationDatum[Int] {
  let subdivisions = sample_count - 1
  let step = domain.length() / cores_float_from_int(subdivisions)
  let steps_taken = (t - domain.start()) / step
  if steps_taken <= 0.0F {
    return LeftTail(0)
  }
  if steps_taken >= cores_float_from_int(subdivisions) {
    return RightTail(sample_count - 1)
  }
  let lower = cores_floor_int(steps_taken)
  let upper = lower + 1
  let s = steps_taken - steps_taken.floor()
  if s <= 1.0e-6F {
    Exact(lower)
  } else {
    Between(lower, upper, s)
  }
}

///|
pub struct UnevenCore[T] {
  sample_points : Array[(Float, T)]
}

///|
pub fn[T] UnevenCore::new(
  sample_points : Array[(Float, T)],
) -> UnevenCore[T] raise UnevenCoreError {
  if sample_points.length() < 2 {
    raise NotEnoughSamples(sample_points.length())
  }
  for index in 0..<sample_points.length() {
    let time = sample_points[index].0
    if !cores_is_finite(time) {
      raise NonFiniteSampleTime
    }
    if index > 0 && time <= sample_points[index - 1].0 {
      raise NonIncreasingSampleTimes
    }
  }
  UnevenCore::{ sample_points, }
}

///|
pub fn[T] UnevenCore::domain(self : UnevenCore[T]) -> @math.Interval {
  @math.Interval::new(
    self.sample_points[0].0,
    self.sample_points[self.sample_points.length() - 1].0,
  ) catch {
    _ => abort("UnevenCore::domain expects sorted finite sample points")
  }
}

///|
pub fn[T] UnevenCore::sample_with(
  self : UnevenCore[T],
  t : Float,
  interpolation : (T, T, Float) -> T,
) -> T {
  match self.sample_interp(t) {
    Exact((_, value)) => value
    LeftTail((_, value)) => value
    RightTail((_, value)) => value
    Between((t0, lhs), (t1, rhs), _) => {
      let width = t1 - t0
      let s = if width <= 0.0F {
        0.0F
      } else {
        (self.domain().clamp(t) - t0) / width
      }
      interpolation(lhs, rhs, s)
    }
  }
}

///|
pub fn[T] UnevenCore::sample_interp(
  self : UnevenCore[T],
  t : Float,
) -> InterpolationDatum[(Float, T)] {
  let clamped = self.domain().clamp(t)
  if clamped <= self.sample_points[0].0 {
    return LeftTail(self.sample_points[0])
  }
  let last_index = self.sample_points.length() - 1
  if clamped >= self.sample_points[last_index].0 {
    return RightTail(self.sample_points[last_index])
  }
  for index in 0..<last_index {
    let lower = self.sample_points[index]
    let upper = self.sample_points[index + 1]
    if clamped == lower.0 {
      return Exact(lower)
    }
    if clamped == upper.0 {
      return Exact(upper)
    }
    if clamped > lower.0 && clamped < upper.0 {
      let width = upper.0 - lower.0
      let s = if width <= 0.0F { 0.0F } else { (clamped - lower.0) / width }
      return Between(lower, upper, s)
    }
  }
  RightTail(self.sample_points[last_index])
}

///|
pub fn[T] even_core(
  domain : @math.Interval,
  samples : Array[T],
) -> EvenCore[T] raise EvenCoreError {
  EvenCore::new(domain, samples)
}

///|
pub fn[T] uneven_core(
  sample_points : Array[(Float, T)],
) -> UnevenCore[T] raise UnevenCoreError {
  UnevenCore::new(sample_points)
}

///|
fn cores_float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn cores_floor_int(value : Float) -> Int {
  value.floor().to_int()
}

///|
fn cores_is_finite(value : Float) -> Bool {
  value == value && value != 1.0F / 0.0F && value != -1.0F / 0.0F
}
