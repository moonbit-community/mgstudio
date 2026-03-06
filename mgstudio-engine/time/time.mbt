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
//
// Adapted from Bevy's `bevy_time` crate.
// Copyright (c) Bevy Contributors.
// Licensed under Apache-2.0 or MIT.

///|
const DEFAULT_TIME_WRAP_PERIOD_SECONDS : Float = 3600.0F

///|
pub struct Time {
  wrap_period_seconds : Float
  delta_seconds : Float
  elapsed_seconds : Float
  elapsed_wrapped_seconds : Float
}

///|
pub fn Time::new() -> Time {
  Time::{
    wrap_period_seconds: DEFAULT_TIME_WRAP_PERIOD_SECONDS,
    delta_seconds: 0.0F,
    elapsed_seconds: 0.0F,
    elapsed_wrapped_seconds: 0.0F,
  }
}

///|
pub fn Time::default() -> Time {
  Time::new()
}

///|
fn time_non_negative_seconds(seconds : Float) -> Float {
  if seconds < 0.0F {
    0.0F
  } else {
    seconds
  }
}

///|
fn time_duration_rem(
  dividend_seconds : Float,
  divisor_seconds : Float,
) -> Float {
  if divisor_seconds <= 0.0F {
    0.0F
  } else {
    let quotient = (dividend_seconds / divisor_seconds).to_int()
    let remainder = dividend_seconds -
      Float::from_int(quotient) * divisor_seconds
    if remainder < 0.0F {
      0.0F
    } else {
      remainder
    }
  }
}

///|
fn time_elapsed_wrapped_seconds_for(
  elapsed_seconds : Float,
  wrap_period_seconds : Float,
) -> Float {
  time_duration_rem(elapsed_seconds, wrap_period_seconds)
}

///|
fn time_time_or_default() -> Time {
  match time_resource.val.get() {
    Some(time) => time
    None => Time::new()
  }
}

///|
fn time_delta_seconds_raw(time : Time) -> Float {
  time.delta_seconds
}

///|
fn time_elapsed_seconds_raw(time : Time) -> Float {
  time.elapsed_seconds
}

///|
fn time_wrap_period_seconds_raw(time : Time) -> Float {
  time.wrap_period_seconds
}

///|
pub fn Time::wrap_period_seconds(self : Time) -> Float {
  self.wrap_period_seconds
}

///|
pub fn Time::set_wrap_period_seconds(
  self : Time,
  wrap_period_seconds : Float,
) -> Time {
  if wrap_period_seconds.is_nan() || wrap_period_seconds.is_inf() {
    abort("tried to set wrap period to a non-finite value")
  }
  if wrap_period_seconds <= 0.0F {
    abort("division by zero")
  }
  Time::{ ..self, wrap_period_seconds, }
}

///|
pub fn Time::advance_by(self : Time, delta_seconds : Float) -> Time {
  if delta_seconds.is_nan() || delta_seconds.is_inf() {
    abort("tried to advance time by a non-finite duration")
  }
  if delta_seconds < 0.0F {
    abort("tried to move time backwards to an earlier elapsed moment")
  }
  let elapsed_seconds = self.elapsed_seconds + delta_seconds
  Time::{
    ..self,
    delta_seconds,
    elapsed_seconds,
    elapsed_wrapped_seconds: time_elapsed_wrapped_seconds_for(
      elapsed_seconds,
      self.wrap_period_seconds,
    ),
  }
}

///|
pub fn Time::advance_to(self : Time, elapsed_seconds : Float) -> Time {
  if elapsed_seconds.is_nan() || elapsed_seconds.is_inf() {
    abort("tried to advance time to a non-finite elapsed moment")
  }
  if elapsed_seconds < self.elapsed_seconds {
    abort("tried to move time backwards to an earlier elapsed moment")
  }
  self.advance_by(elapsed_seconds - self.elapsed_seconds)
}

///|
pub fn Time::delta_seconds(self : Time) -> Float {
  self.delta_seconds
}

///|
pub fn Time::delta_secs(self : Time) -> Float {
  self.delta_seconds()
}

///|
pub fn Time::delta_secs_f64(self : Time) -> Float {
  self.delta_seconds()
}

///|
pub fn Time::elapsed_seconds(self : Time) -> Float {
  self.elapsed_seconds
}

///|
pub fn Time::elapsed_secs(self : Time) -> Float {
  self.elapsed_seconds()
}

///|
pub fn Time::elapsed_secs_f64(self : Time) -> Float {
  self.elapsed_seconds()
}

///|
pub fn Time::elapsed_wrapped_seconds(self : Time) -> Float {
  self.elapsed_wrapped_seconds
}

///|
pub fn Time::elapsed_secs_wrapped(self : Time) -> Float {
  self.elapsed_wrapped_seconds()
}

///|
pub fn Time::elapsed_secs_wrapped_f64(self : Time) -> Float {
  self.elapsed_wrapped_seconds()
}

///|
pub fn Time::as_generic(self : Time) -> Time {
  self
}

///|
pub fn time_delta_seconds() -> Float {
  time_time_or_default().delta_seconds()
}

///|
pub fn time_elapsed_seconds() -> Float {
  time_time_or_default().elapsed_seconds()
}
