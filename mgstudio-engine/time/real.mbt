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
pub struct Real {
  time : Time
  startup_seconds : Float
  first_update_seconds : Float?
  last_update_seconds : Float?
}

///|
pub fn Real::new(startup_seconds : Float) -> Real {
  Real::{
    time: Time::new(),
    startup_seconds,
    first_update_seconds: None,
    last_update_seconds: None,
  }
}

///|
pub fn Real::default() -> Real {
  Real::new(0.0F)
}

///|
pub fn Real::update(self : Real) -> Real {
  self.update_with_instant(host_time_now())
}

///|
pub fn Real::update_with_duration(
  self : Real,
  duration_seconds : Float,
) -> Real {
  let non_negative_duration = time_non_negative_seconds(duration_seconds)
  let last_update_seconds = match self.last_update_seconds {
    Some(last_update_seconds) => last_update_seconds
    None => self.startup_seconds
  }
  self.update_with_instant(last_update_seconds + non_negative_duration)
}

///|
pub fn Real::update_with_instant(self : Real, instant_seconds : Float) -> Real {
  if instant_seconds.is_nan() || instant_seconds.is_inf() {
    abort("tried to update real time with a non-finite instant")
  }
  match self.last_update_seconds {
    None =>
      Real::{
        ..self,
        first_update_seconds: Some(instant_seconds),
        last_update_seconds: Some(instant_seconds),
      }
    Some(last_update_seconds) => {
      let delta_seconds = if instant_seconds > last_update_seconds {
        instant_seconds - last_update_seconds
      } else {
        0.0F
      }
      Real::{
        ..self,
        time: self.time.advance_by(delta_seconds),
        last_update_seconds: Some(instant_seconds),
      }
    }
  }
}

///|
pub fn Real::startup_seconds(self : Real) -> Float {
  self.startup_seconds
}

///|
pub fn Real::first_update_seconds(self : Real) -> Float? {
  self.first_update_seconds
}

///|
pub fn Real::last_update_seconds(self : Real) -> Float? {
  self.last_update_seconds
}

///|
pub fn Real::delta_seconds(self : Real) -> Float {
  time_delta_seconds_raw(self.time)
}

///|
pub fn Real::elapsed_seconds(self : Real) -> Float {
  time_elapsed_seconds_raw(self.time)
}

///|
pub fn Real::as_generic(self : Real) -> Time {
  self.time.as_generic()
}

///|
fn time_real_or_default() -> Real {
  match real_resource.val.get() {
    Some(real) => real
    None => Real::default()
  }
}

///|
pub fn time_real_delta_seconds() -> Float {
  time_real_or_default().delta_seconds()
}

///|
pub fn time_real_elapsed_seconds() -> Float {
  time_real_or_default().elapsed_seconds()
}
