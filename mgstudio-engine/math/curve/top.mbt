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
// Bevy source: `bevy/crates/bevy_math/src/curve/mod.rs`.

///|
pub(all) suberror CurveChainError {
  UnboundedDomain
}

///|
pub struct Curve[T] {
  domain_ : Interval
  sample_unchecked_fn : (Float) -> T
}

///|
pub fn[T] Curve::new(
  domain : Interval,
  sample_unchecked : (Float) -> T,
) -> Curve[T] {
  Curve::{ domain_: domain, sample_unchecked_fn: sample_unchecked }
}

///|
pub fn[T] Curve::domain(self : Curve[T]) -> Interval {
  self.domain_
}

///|
pub fn[T] Curve::sample_unchecked(self : Curve[T], t : Float) -> T {
  (self.sample_unchecked_fn)(t)
}

///|
pub fn[T] Curve::sample_clamped(self : Curve[T], t : Float) -> T {
  self.sample_unchecked(self.domain_.clamp(t))
}

///|
pub fn[T] Curve::sample(self : Curve[T], t : Float) -> T? {
  if self.domain_.contains(t) {
    Some(self.sample_unchecked(t))
  } else {
    None
  }
}

///|
pub fn[T, S] Curve::map(self : Curve[T], f : (T) -> S) -> Curve[S] {
  Curve::new(self.domain_, fn(t) { f(self.sample_unchecked(t)) })
}

///|
pub fn[T] Curve::graph(self : Curve[T]) -> Curve[(Float, T)] {
  Curve::new(self.domain_, fn(t) { (t, self.sample_unchecked(t)) })
}

///|
pub fn[T] Curve::reparametrize(
  self : Curve[T],
  domain : Interval,
  f : (Float) -> Float,
) -> Curve[T] {
  Curve::new(domain, fn(t) { self.sample_clamped(f(t)) })
}

///|
pub fn[T] Curve::reparametrize_linear(
  self : Curve[T],
  domain : Interval,
) -> Curve[T] raise LinearMapError {
  if !domain.is_bounded() {
    raise TargetUnbounded
  }
  if !self.domain_.is_bounded() {
    raise SourceUnbounded
  }
  Curve::new(domain, fn(t) {
    let mapped = domain.linear_map_value_to(self.domain_, t) catch {
      _ => abort("Curve::reparametrize_linear requires bounded domains")
    }
    self.sample_clamped(mapped)
  })
}

///|
pub fn[T] Curve::reverse(self : Curve[T]) -> Curve[T] raise LinearMapError {
  if !self.domain_.is_bounded() {
    raise SourceUnbounded
  }
  let source = self.domain_
  Curve::new(source, fn(t) {
    let mirrored = source.end_() - (t - source.start())
    self.sample_clamped(mirrored)
  })
}

///|
pub fn[T, S] Curve::zip(
  self : Curve[T],
  other : Curve[S],
) -> Curve[(T, S)] raise InvalidIntervalError {
  let shared = self.domain_.intersect(other.domain_)
  Curve::new(shared, fn(t) { (self.sample_clamped(t), other.sample_clamped(t)) })
}

///|
pub fn[T] Curve::chain(
  self : Curve[T],
  other : Curve[T],
) -> Curve[T] raise CurveChainError {
  if !self.domain_.is_bounded() || !other.domain_.is_bounded() {
    raise UnboundedDomain
  }
  let chained_domain = Interval::new(
    self.domain_.start(),
    self.domain_.start() + self.domain_.length() + other.domain_.length(),
  ) catch {
    _ => abort("Curve::chain expects finite bounded source intervals")
  }
  let split = self.domain_.start() + self.domain_.length()
  Curve::new(chained_domain, fn(t) {
    if t <= split {
      self.sample_clamped(t)
    } else {
      let shifted = other.domain_.start() + (t - split)
      other.sample_clamped(shifted)
    }
  })
}

///|
pub fn[T] Curve::samples(
  self : Curve[T],
  points : Int,
) -> Array[T] raise SpacedPointsError {
  let times = self.domain_.spaced_points(points)
  let values : Array[T] = []
  for time in times {
    values.push(self.sample_clamped(time))
  }
  values
}

///|
pub fn[T] Curve::resample(
  self : Curve[T],
  points : Int,
  interpolation : (T, T, Float) -> T,
) -> SampleCurve[T] raise EvenCoreError {
  let values = self.samples(points) catch {
    _ => raise EvenCoreError::UnboundedDomain
  }
  SampleCurve::new(self.domain_, values, interpolation)
}

///|
pub fn[T] Curve::resample_auto(
  self : Curve[T],
  points : Int,
) -> SampleAutoCurve[T] raise EvenCoreError {
  let values = self.samples(points) catch {
    _ => raise EvenCoreError::UnboundedDomain
  }
  SampleAutoCurve::new(self.domain_, values)
}
