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
const DEFAULT_FIXED_TIMESTEP_SECONDS : Float = 0.015625F

///|
pub struct Fixed {
  time : Time
  timestep_seconds : Float
  overstep_seconds : Float
}

///|
pub fn Fixed::new() -> Fixed {
  Fixed::{
    time: Time::new(),
    timestep_seconds: DEFAULT_FIXED_TIMESTEP_SECONDS,
    overstep_seconds: 0.0F,
  }
}

///|
pub fn Fixed::default() -> Fixed {
  Fixed::new()
}

///|
pub fn Fixed::from_duration_seconds(timestep_seconds : Float) -> Fixed {
  Fixed::new().set_timestep_seconds(timestep_seconds)
}

///|
pub fn Fixed::from_seconds(seconds : Float) -> Fixed {
  Fixed::from_duration_seconds(seconds)
}

///|
pub fn Fixed::from_hz(hz : Float) -> Fixed {
  if hz.is_nan() || hz.is_inf() {
    abort("Hz is infinite")
  }
  if hz <= 0.0F {
    abort("Hz less than or equal to zero")
  }
  Fixed::from_seconds(1.0F / hz)
}

///|
pub fn Fixed::delta_seconds(self : Fixed) -> Float {
  time_delta_seconds_raw(self.time)
}

///|
pub fn Fixed::elapsed_seconds(self : Fixed) -> Float {
  time_elapsed_seconds_raw(self.time)
}

///|
pub fn Fixed::timestep_seconds(self : Fixed) -> Float {
  self.timestep_seconds
}

///|
pub fn Fixed::set_timestep_seconds(self : Fixed, seconds : Float) -> Fixed {
  if seconds.is_nan() || seconds.is_inf() {
    abort("seconds is infinite")
  }
  if seconds <= 0.0F {
    abort("attempted to set fixed timestep to zero")
  }
  Fixed::{ ..self, timestep_seconds: seconds }
}

///|
pub fn Fixed::set_timestep_hz(self : Fixed, hz : Float) -> Fixed {
  if hz.is_nan() || hz.is_inf() {
    abort("Hz is infinite")
  }
  if hz <= 0.0F {
    abort("Hz less than or equal to zero")
  }
  self.set_timestep_seconds(1.0F / hz)
}

///|
pub fn Fixed::overstep_seconds(self : Fixed) -> Float {
  self.overstep_seconds
}

///|
pub fn Fixed::accumulate_overstep(self : Fixed, delta_seconds : Float) -> Fixed {
  Fixed::{
    ..self,
    overstep_seconds: self.overstep_seconds +
    time_non_negative_seconds(delta_seconds),
  }
}

///|
pub fn Fixed::discard_overstep(self : Fixed, discard_seconds : Float) -> Fixed {
  let overstep_seconds = self.overstep_seconds -
    time_non_negative_seconds(discard_seconds)
  Fixed::{
    ..self,
    overstep_seconds: if overstep_seconds < 0.0F {
      0.0F
    } else {
      overstep_seconds
    },
  }
}

///|
pub fn Fixed::overstep_fraction(self : Fixed) -> Float {
  if self.timestep_seconds <= 0.0F {
    0.0F
  } else {
    self.overstep_seconds / self.timestep_seconds
  }
}

///|
pub fn Fixed::overstep_fraction_f64(self : Fixed) -> Float {
  self.overstep_fraction()
}

///|
pub fn Fixed::as_generic(self : Fixed) -> Time {
  self.time.as_generic()
}

///|
pub fn Fixed::set_runtime_state(
  self : Fixed,
  timestep_seconds : Float,
  overstep_seconds : Float,
  elapsed_seconds : Float,
) -> Fixed {
  let time = if elapsed_seconds < time_elapsed_seconds_raw(self.time) {
    Time::new()
    .set_wrap_period_seconds(time_wrap_period_seconds_raw(self.time))
    .advance_to(elapsed_seconds)
  } else {
    self.time.advance_to(elapsed_seconds)
  }
  Fixed::{ time, timestep_seconds, overstep_seconds }
}

///|
pub fn Fixed::expend(self : Fixed) -> Fixed? {
  if self.overstep_seconds < self.timestep_seconds {
    None
  } else {
    Some(Fixed::{
      ..self.discard_overstep(self.timestep_seconds),
      time: self.time.advance_by(self.timestep_seconds),
    })
  }
}
