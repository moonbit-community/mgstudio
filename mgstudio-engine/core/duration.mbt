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
const NANOS_PER_MICRO : Int64 = 1_000L

///|
const NANOS_PER_MILLI : Int64 = 1_000_000L

///|
const NANOS_PER_SEC : Int64 = 1_000_000_000L

///|
const DURATION_MAX_NANOS : Int64 = 9_223_372_036_854_775_807L

///|
pub struct Duration {
  nanos : Int64
} derive(Eq, Debug, ToJson, FromJson)

///|
fn duration_clamp_non_negative_nanos(nanos : Int64) -> Int64 {
  if nanos <= 0L {
    0L
  } else {
    nanos
  }
}

///|
fn duration_add_saturating(lhs : Int64, rhs : Int64) -> Int64 {
  if lhs >= DURATION_MAX_NANOS - rhs {
    DURATION_MAX_NANOS
  } else {
    lhs + rhs
  }
}

///|
fn duration_from_double_seconds(seconds : Double) -> Duration {
  if seconds <= 0.0 || seconds.is_nan() {
    return Duration::{ nanos: 0L }
  }
  if seconds.is_inf() {
    return Duration::{ nanos: DURATION_MAX_NANOS }
  }
  let nanos = (seconds * NANOS_PER_SEC.to_double()).to_int64()
  Duration::{ nanos: duration_clamp_non_negative_nanos(nanos) }
}

///|
pub fn Duration::new(secs : Int64, nanos? : Int = 0) -> Duration {
  let nanos_from_secs = if secs <= 0L {
    0L
  } else if secs >= DURATION_MAX_NANOS / NANOS_PER_SEC {
    DURATION_MAX_NANOS
  } else {
    secs * NANOS_PER_SEC
  }
  let extra_nanos = if nanos <= 0 { 0L } else { nanos.to_int64() }
  Duration::{ nanos: duration_add_saturating(nanos_from_secs, extra_nanos) }
}

///|
pub fn Duration::zero() -> Duration {
  Duration::{ nanos: 0L }
}

///|
pub fn Duration::from_secs(secs : Int64) -> Duration {
  Duration::new(secs)
}

///|
pub fn Duration::from_secs_f32(secs : Float) -> Duration {
  duration_from_double_seconds(secs.to_double())
}

///|
pub fn Duration::from_secs_f64(secs : Double) -> Duration {
  duration_from_double_seconds(secs)
}

///|
pub fn Duration::from_millis(millis : Int64) -> Duration {
  Duration::{
    nanos: duration_clamp_non_negative_nanos(millis * NANOS_PER_MILLI),
  }
}

///|
pub fn Duration::from_micros(micros : Int64) -> Duration {
  Duration::{
    nanos: duration_clamp_non_negative_nanos(micros * NANOS_PER_MICRO),
  }
}

///|
pub fn Duration::from_nanos(nanos : Int64) -> Duration {
  Duration::{ nanos: duration_clamp_non_negative_nanos(nanos) }
}

///|
pub fn Duration::as_nanos(self : Duration) -> Int64 {
  self.nanos
}

///|
pub fn Duration::as_micros(self : Duration) -> Int64 {
  self.nanos / NANOS_PER_MICRO
}

///|
pub fn Duration::as_millis(self : Duration) -> Int64 {
  self.nanos / NANOS_PER_MILLI
}

///|
pub fn Duration::as_secs_f32(self : Duration) -> Float {
  Float::from_double(self.as_secs_f64())
}

///|
pub fn Duration::as_secs_f64(self : Duration) -> Double {
  self.nanos.to_double() / NANOS_PER_SEC.to_double()
}

///|
pub fn Duration::is_zero(self : Duration) -> Bool {
  self.nanos == 0L
}

///|
pub fn Duration::checked_sub(self : Duration, other : Duration) -> Duration? {
  let remaining = self.nanos - other.nanos
  if remaining < 0L {
    None
  } else {
    Some(Duration::{ nanos: remaining })
  }
}

///|
pub fn Duration::saturating_add(self : Duration, other : Duration) -> Duration {
  Duration::{ nanos: duration_add_saturating(self.nanos, other.nanos) }
}

///|
pub fn Duration::saturating_sub(self : Duration, other : Duration) -> Duration {
  match self.checked_sub(other) {
    Some(duration) => duration
    None => Duration::zero()
  }
}

///|
pub fn Duration::mul_f64(self : Duration, factor : Double) -> Duration {
  if factor.is_nan() || factor.is_inf() {
    abort("tried to scale duration by a non-finite factor")
  }
  if factor <= 0.0 {
    return Duration::zero()
  }
  let nanos = (self.nanos.to_double() * factor).to_int64()
  Duration::{ nanos: duration_clamp_non_negative_nanos(nanos) }
}

///|
pub fn Duration::mul_int(self : Duration, factor : Int) -> Duration {
  if factor <= 0 {
    Duration::zero()
  } else if self.nanos > DURATION_MAX_NANOS / factor.to_int64() {
    Duration::{ nanos: DURATION_MAX_NANOS }
  } else {
    Duration::{ nanos: self.nanos * factor.to_int64() }
  }
}
