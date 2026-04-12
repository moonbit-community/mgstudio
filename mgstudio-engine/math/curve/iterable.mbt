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
// Bevy source: `bevy/crates/bevy_math/src/curve/iterable.rs`.

///|
pub struct IterableCurve[T] {
  domain_ : @math.Interval
  sample_iter_unchecked_fn : (Float) -> Iter[T]
}

///|
pub fn[T] IterableCurve::new(
  domain : @math.Interval,
  sample_iter_unchecked : (Float) -> Iter[T],
) -> IterableCurve[T] {
  IterableCurve::{
    domain_: domain,
    sample_iter_unchecked_fn: sample_iter_unchecked,
  }
}

///|
pub fn[T] IterableCurve::domain(self : IterableCurve[T]) -> @math.Interval {
  self.domain_
}

///|
pub fn[T] IterableCurve::sample_iter_unchecked(
  self : IterableCurve[T],
  t : Float,
) -> Iter[T] {
  (self.sample_iter_unchecked_fn)(t)
}

///|
pub fn[T] IterableCurve::sample_iter_clamped(
  self : IterableCurve[T],
  t : Float,
) -> Iter[T] {
  self.sample_iter_unchecked(self.domain_.clamp(t))
}

///|
pub fn[T] IterableCurve::sample_iter(
  self : IterableCurve[T],
  t : Float,
) -> Iter[T]? {
  if self.domain_.contains(t) {
    Some(self.sample_iter_unchecked(t))
  } else {
    None
  }
}

///|
pub fn[T] iterable_curve(
  domain : @math.Interval,
  sample_iter_unchecked : (Float) -> Iter[T],
) -> IterableCurve[T] {
  IterableCurve::new(domain, sample_iter_unchecked)
}

///|
pub fn[T] sample_iter(curve : IterableCurve[T], t : Float) -> Iter[T]? {
  curve.sample_iter(t)
}
