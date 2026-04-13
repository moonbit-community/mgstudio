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
pub(all) suberror InvalidIntervalError {
  Invalid
}

///|
pub(all) suberror SpacedPointsError {
  Unbounded
}

///|
pub(all) suberror LinearMapError {
  SourceUnbounded
  TargetUnbounded
}

///|
pub(all) struct Interval {
  start_ : Float
  end_ : Float
} derive(Eq, Debug, ToJson, FromJson)

///|
pub fn Interval::new(
  start_ : Float,
  end_ : Float,
) -> Interval raise InvalidIntervalError {
  if start_ >= end_ || interval_is_nan(start_) || interval_is_nan(end_) {
    raise Invalid
  } else {
    Interval::{ start_, end_ }
  }
}

///|
pub fn Interval::unit() -> Interval {
  Interval::{ start_: 0.0F, end_: 1.0F }
}

///|
pub fn Interval::everywhere() -> Interval {
  Interval::{ start_: interval_neg_infinity(), end_: interval_infinity() }
}

///|
pub fn Interval::start(self : Interval) -> Float {
  self.start_
}

///|
pub fn Interval::end_(self : Interval) -> Float {
  self.end_
}

///|
pub fn Interval::length(self : Interval) -> Float {
  self.end_ - self.start_
}

///|
pub fn Interval::is_bounded(self : Interval) -> Bool {
  interval_is_finite(self.start_) && interval_is_finite(self.end_)
}

///|
pub fn Interval::has_finite_start(self : Interval) -> Bool {
  interval_is_finite(self.start_)
}

///|
pub fn Interval::has_finite_end(self : Interval) -> Bool {
  interval_is_finite(self.end_)
}

///|
pub fn Interval::contains(self : Interval, item : Float) -> Bool {
  item >= self.start_ && item <= self.end_
}

///|
pub fn Interval::contains_interval(self : Interval, other : Interval) -> Bool {
  self.start_ <= other.start_ && self.end_ >= other.end_
}

///|
pub fn Interval::clamp(self : Interval, value : Float) -> Float {
  if value < self.start_ {
    self.start_
  } else if value > self.end_ {
    self.end_
  } else {
    value
  }
}

///|
pub fn Interval::intersect(
  self : Interval,
  other : Interval,
) -> Interval raise InvalidIntervalError {
  let lower = interval_maxf(self.start_, other.start_)
  let upper = interval_minf(self.end_, other.end_)
  Interval::new(lower, upper)
}

///|
pub fn Interval::spaced_points(
  self : Interval,
  points : Int,
) -> Array[Float] raise SpacedPointsError {
  if !self.is_bounded() {
    raise Unbounded
  }
  if points <= 0 {
    return []
  }
  if points == 1 {
    return [self.start_]
  }
  let values : Array[Float] = []
  let step = self.length() / interval_float_from_int(points - 1)
  for index in 0..<points {
    values.push(self.start_ + interval_float_from_int(index) * step)
  }
  values
}

///|
pub fn Interval::linear_map_value_to(
  self : Interval,
  other : Interval,
  value : Float,
) -> Float raise LinearMapError {
  if !self.is_bounded() {
    raise SourceUnbounded
  }
  if !other.is_bounded() {
    raise TargetUnbounded
  }
  let scale = other.length() / self.length()
  (value - self.start_) * scale + other.start_
}

///|
pub fn interval(
  start_ : Float,
  end_ : Float,
) -> Interval raise InvalidIntervalError {
  Interval::new(start_, end_)
}

///|
fn interval_minf(a : Float, b : Float) -> Float {
  if a < b {
    a
  } else {
    b
  }
}

///|
fn interval_maxf(a : Float, b : Float) -> Float {
  if a > b {
    a
  } else {
    b
  }
}

///|
fn interval_float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn interval_is_nan(value : Float) -> Bool {
  value != value
}

///|
fn interval_is_finite(value : Float) -> Bool {
  !interval_is_nan(value) &&
  value != interval_infinity() &&
  value != interval_neg_infinity()
}

///|
fn interval_infinity() -> Float {
  1.0F / 0.0F
}

///|
fn interval_neg_infinity() -> Float {
  -1.0F / 0.0F
}
