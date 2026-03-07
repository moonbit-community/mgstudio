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
const DEFAULT_VIRTUAL_MAX_DELTA_SECONDS : Float = 0.25F

///|
pub struct Virtual {
  time : Time
  max_delta_seconds : Float
  paused : Bool
  relative_speed : Float
  effective_speed : Float
}

///|
pub fn Virtual::new() -> Virtual {
  Virtual::{
    time: Time::new(),
    max_delta_seconds: DEFAULT_VIRTUAL_MAX_DELTA_SECONDS,
    paused: false,
    relative_speed: 1.0F,
    effective_speed: 1.0F,
  }
}

///|
pub fn Virtual::default() -> Virtual {
  Virtual::new()
}

///|
pub fn Virtual::from_max_delta_seconds(max_delta_seconds : Float) -> Virtual {
  Virtual::new().set_max_delta_seconds(max_delta_seconds)
}

///|
pub fn Virtual::delta_seconds(self : Virtual) -> Float {
  time_delta_seconds_raw(self.time)
}

///|
pub fn Virtual::elapsed_seconds(self : Virtual) -> Float {
  time_elapsed_seconds_raw(self.time)
}

///|
pub fn Virtual::relative_speed(self : Virtual) -> Float {
  self.relative_speed
}

///|
pub fn Virtual::relative_speed_f64(self : Virtual) -> Float {
  self.relative_speed
}

///|
pub fn Virtual::effective_speed(self : Virtual) -> Float {
  self.effective_speed
}

///|
pub fn Virtual::effective_speed_f64(self : Virtual) -> Float {
  self.effective_speed
}

///|
pub fn Virtual::max_delta_seconds(self : Virtual) -> Float {
  self.max_delta_seconds
}

///|
pub fn Virtual::is_paused(self : Virtual) -> Bool {
  self.paused
}

///|
pub fn Virtual::was_paused(self : Virtual) -> Bool {
  self.effective_speed == 0.0F
}

///|
pub fn Virtual::set_relative_speed(self : Virtual, speed : Float) -> Virtual {
  if speed.is_nan() || speed.is_inf() {
    abort("tried to go infinitely fast")
  }
  if speed < 0.0F {
    abort("tried to go back in time")
  }
  Virtual::{ ..self, relative_speed: speed }
}

///|
pub fn Virtual::set_relative_speed_f64(
  self : Virtual,
  speed : Float,
) -> Virtual {
  self.set_relative_speed(speed)
}

///|
pub fn Virtual::set_max_delta_seconds(
  self : Virtual,
  max_delta_seconds : Float,
) -> Virtual {
  if max_delta_seconds.is_nan() || max_delta_seconds.is_inf() {
    abort("tried to set max delta to a non-finite value")
  }
  if max_delta_seconds <= 0.0F {
    abort("tried to set max delta to zero")
  }
  Virtual::{ ..self, max_delta_seconds, }
}

///|
pub fn Virtual::pause(self : Virtual) -> Virtual {
  Virtual::{ ..self, paused: true }
}

///|
pub fn Virtual::unpause(self : Virtual) -> Virtual {
  Virtual::{ ..self, paused: false }
}

///|
pub fn Virtual::toggle(self : Virtual) -> Virtual {
  Virtual::{ ..self, paused: !self.paused }
}

///|
pub fn Virtual::advance_with_raw_delta(
  self : Virtual,
  raw_delta_seconds : Float,
) -> Virtual {
  let clamped_raw_delta = if raw_delta_seconds > self.max_delta_seconds {
    self.max_delta_seconds
  } else {
    time_non_negative_seconds(raw_delta_seconds)
  }
  let effective_speed = if self.paused { 0.0F } else { self.relative_speed }
  Virtual::{
    ..self,
    time: self.time.advance_by(clamped_raw_delta * effective_speed),
    effective_speed,
  }
}

///|
pub fn Virtual::as_generic(self : Virtual) -> Time {
  self.time.as_generic()
}

///|
pub fn update_virtual_time(virtual_time : Virtual, real_time : Real) -> Virtual {
  virtual_time.advance_with_raw_delta(real_time.delta_seconds())
}

///|
fn world_virtual_or_default(world : @ecs.World) -> Virtual {
  world_time_resource_or_default(world, virtual_resource_key, Virtual::default)
}

///|
pub fn time_virtual_delta_seconds() -> Float {
  world_virtual_or_default(current_time_world_abort_missing()).delta_seconds()
}

///|
pub fn time_virtual_elapsed_seconds() -> Float {
  world_virtual_or_default(current_time_world_abort_missing()).elapsed_seconds()
}

///|
pub fn time_virtual_relative_speed() -> Float {
  world_virtual_or_default(current_time_world_abort_missing()).relative_speed()
}

///|
pub fn time_virtual_effective_speed() -> Float {
  world_virtual_or_default(current_time_world_abort_missing()).effective_speed()
}

///|
pub fn time_virtual_max_delta_seconds() -> Float {
  world_virtual_or_default(current_time_world_abort_missing()).max_delta_seconds()
}

///|
pub fn time_virtual_is_paused() -> Bool {
  world_virtual_or_default(current_time_world_abort_missing()).is_paused()
}
