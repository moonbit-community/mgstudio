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
let default_virtual_max_delta : @core.Duration = @core.Duration::from_millis(
  250L,
)

///|
pub struct Virtual {
  time : Time
  max_delta : @core.Duration
  paused : Bool
  relative_speed : Double
  effective_speed : Double
}

///|
pub fn Virtual::new() -> Virtual {
  Virtual::{
    time: Time::new(),
    max_delta: default_virtual_max_delta,
    paused: false,
    relative_speed: 1.0,
    effective_speed: 1.0,
  }
}

///|
pub fn Virtual::default() -> Virtual {
  Virtual::new()
}

///|
pub fn Virtual::from_max_delta(max_delta : @core.Duration) -> Virtual {
  Virtual::new().set_max_delta(max_delta)
}

///|
pub fn Virtual::from_max_delta_seconds(max_delta_seconds : Float) -> Virtual {
  Virtual::from_max_delta(@core.Duration::from_secs_f32(max_delta_seconds))
}

///|
pub fn Virtual::delta(self : Virtual) -> @core.Duration {
  time_delta_raw(self.time)
}

///|
pub fn Virtual::delta_seconds(self : Virtual) -> Float {
  time_delta_seconds_raw(self.time)
}

///|
pub fn Virtual::elapsed(self : Virtual) -> @core.Duration {
  time_elapsed_raw(self.time)
}

///|
pub fn Virtual::elapsed_seconds(self : Virtual) -> Float {
  time_elapsed_seconds_raw(self.time)
}

///|
pub fn Virtual::relative_speed(self : Virtual) -> Float {
  Float::from_double(self.relative_speed)
}

///|
pub fn Virtual::relative_speed_f64(self : Virtual) -> Double {
  self.relative_speed
}

///|
pub fn Virtual::effective_speed(self : Virtual) -> Float {
  Float::from_double(self.effective_speed)
}

///|
pub fn Virtual::effective_speed_f64(self : Virtual) -> Double {
  self.effective_speed
}

///|
pub fn Virtual::max_delta(self : Virtual) -> @core.Duration {
  self.max_delta
}

///|
pub fn Virtual::max_delta_seconds(self : Virtual) -> Float {
  self.max_delta.as_secs_f32()
}

///|
pub fn Virtual::is_paused(self : Virtual) -> Bool {
  self.paused
}

///|
pub fn Virtual::was_paused(self : Virtual) -> Bool {
  self.effective_speed == 0.0
}

///|
pub fn Virtual::set_relative_speed(self : Virtual, speed : Float) -> Virtual {
  self.set_relative_speed_f64(speed.to_double())
}

///|
pub fn Virtual::set_relative_speed_f64(
  self : Virtual,
  speed : Double,
) -> Virtual {
  if speed.is_nan() || speed.is_inf() {
    abort("tried to go infinitely fast")
  }
  if speed < 0.0 {
    abort("tried to go back in time")
  }
  Virtual::{ ..self, relative_speed: speed }
}

///|
pub fn Virtual::set_max_delta(
  self : Virtual,
  max_delta : @core.Duration,
) -> Virtual {
  if max_delta.is_zero() {
    abort("tried to set max delta to zero")
  }
  Virtual::{ ..self, max_delta, }
}

///|
pub fn Virtual::set_max_delta_seconds(
  self : Virtual,
  max_delta_seconds : Float,
) -> Virtual {
  self.set_max_delta(@core.Duration::from_secs_f32(max_delta_seconds))
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
  raw_delta : @core.Duration,
) -> Virtual {
  let clamped_raw_delta = if raw_delta.as_nanos() > self.max_delta.as_nanos() {
    self.max_delta
  } else {
    raw_delta
  }
  let effective_speed = if self.paused { 0.0 } else { self.relative_speed }
  let delta = if effective_speed == 1.0 {
    clamped_raw_delta
  } else {
    clamped_raw_delta.mul_f64(effective_speed)
  }
  Virtual::{ ..self, time: self.time.advance_by(delta), effective_speed }
}

///|
pub fn Virtual::as_generic(self : Virtual) -> Time {
  self.time.as_generic()
}

///|
pub fn update_virtual_time(virtual_time : Virtual, real_time : Real) -> Virtual {
  virtual_time.advance_with_raw_delta(real_time.delta())
}

///|
fn world_virtual_or_default(world : @ecs.World) -> Virtual {
  world_time_resource_or_default(world, virtual_resource_key, Virtual::default)
}

///|
pub fn time_virtual_delta() -> @core.Duration {
  world_virtual_or_default(current_time_world_abort_missing()).delta()
}

///|
pub fn time_virtual_delta_seconds() -> Float {
  world_virtual_or_default(current_time_world_abort_missing()).delta_seconds()
}

///|
pub fn time_virtual_elapsed() -> @core.Duration {
  world_virtual_or_default(current_time_world_abort_missing()).elapsed()
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
pub fn time_virtual_max_delta() -> @core.Duration {
  world_virtual_or_default(current_time_world_abort_missing()).max_delta()
}

///|
pub fn time_virtual_max_delta_seconds() -> Float {
  world_virtual_or_default(current_time_world_abort_missing()).max_delta_seconds()
}

///|
pub fn time_virtual_is_paused() -> Bool {
  world_virtual_or_default(current_time_world_abort_missing()).is_paused()
}
