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
// Bevy source: `bevy/crates/bevy_math/src/curve/adaptors.rs`.

///|
pub struct ConstantCurve[T] {
  domain_ : Interval
  value : T
}

///|
pub fn[T] ConstantCurve::new(domain : Interval, value : T) -> ConstantCurve[T] {
  ConstantCurve::{ domain_: domain, value }
}

///|
pub fn[T] ConstantCurve::sample_unchecked(
  self : ConstantCurve[T],
  _t : Float,
) -> T {
  self.value
}

///|
pub fn[T] ConstantCurve::sample_clamped(
  self : ConstantCurve[T],
  _t : Float,
) -> T {
  self.value
}

///|
pub fn[T] ConstantCurve::sample(self : ConstantCurve[T], t : Float) -> T? {
  if self.domain_.contains(t) {
    Some(self.value)
  } else {
    None
  }
}

///|
pub fn[T] ConstantCurve::to_curve(self : ConstantCurve[T]) -> Curve[T] {
  Curve::new(self.domain_, fn(_t) { self.value })
}

///|
pub fn[T] ConstantCurve::domain(self : ConstantCurve[T]) -> Interval {
  self.domain_
}

///|
pub struct FunctionCurve[T] {
  domain_ : Interval
  f : (Float) -> T
}

///|
pub fn[T] FunctionCurve::new(
  domain : Interval,
  f : (Float) -> T,
) -> FunctionCurve[T] {
  FunctionCurve::{ domain_: domain, f }
}

///|
pub fn[T] FunctionCurve::sample_unchecked(
  self : FunctionCurve[T],
  t : Float,
) -> T {
  (self.f)(t)
}

///|
pub fn[T] FunctionCurve::sample_clamped(
  self : FunctionCurve[T],
  t : Float,
) -> T {
  (self.f)(self.domain_.clamp(t))
}

///|
pub fn[T] FunctionCurve::sample(self : FunctionCurve[T], t : Float) -> T? {
  if self.domain_.contains(t) {
    Some((self.f)(t))
  } else {
    None
  }
}

///|
pub fn[T] FunctionCurve::to_curve(self : FunctionCurve[T]) -> Curve[T] {
  Curve::new(self.domain_, self.f)
}

///|
pub fn[T] FunctionCurve::domain(self : FunctionCurve[T]) -> Interval {
  self.domain_
}

///|
pub fn[T] constant_curve(domain : Interval, value : T) -> ConstantCurve[T] {
  ConstantCurve::new(domain, value)
}

///|
pub fn[T] function_curve(
  domain : Interval,
  f : (Float) -> T,
) -> FunctionCurve[T] {
  FunctionCurve::new(domain, f)
}
