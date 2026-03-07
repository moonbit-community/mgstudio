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
  max_delta : @core.Duration
  paused : Bool
  relative_speed : Double
  effective_speed : Double
}

///|
pub impl Default for Virtual with default() {
  {
    max_delta: default_virtual_max_delta,
    paused: false,
    relative_speed: 1.0,
    effective_speed: 1.0,
  }
}

///|
pub fn Time::from_max_delta(max_delta : @core.Duration) -> Time[Virtual] {
  let virtual_time : Time[Virtual] = Time::default()
  virtual_time.set_max_delta(max_delta)
}

///|
pub fn Time::from_max_delta_seconds(max_delta_seconds : Float) -> Time[Virtual] {
  Time::from_max_delta(@core.Duration::from_secs_f32(max_delta_seconds))
}

///|
pub fn Time::relative_speed(self : Time[Virtual]) -> Float {
  Float::from_double(self.context().relative_speed)
}

///|
pub fn Time::relative_speed_f64(self : Time[Virtual]) -> Double {
  self.context().relative_speed
}

///|
pub fn Time::effective_speed(self : Time[Virtual]) -> Float {
  Float::from_double(self.context().effective_speed)
}

///|
pub fn Time::effective_speed_f64(self : Time[Virtual]) -> Double {
  self.context().effective_speed
}

///|
pub fn Time::max_delta(self : Time[Virtual]) -> @core.Duration {
  self.context().max_delta
}

///|
pub fn Time::max_delta_seconds(self : Time[Virtual]) -> Float {
  self.max_delta().as_secs_f32()
}

///|
pub fn Time::is_paused(self : Time[Virtual]) -> Bool {
  self.context().paused
}

///|
pub fn Time::was_paused(self : Time[Virtual]) -> Bool {
  self.context().effective_speed == 0.0
}

///|
pub fn Time::set_relative_speed(
  self : Time[Virtual],
  speed : Float,
) -> Time[Virtual] {
  self.set_relative_speed_f64(speed.to_double())
}

///|
pub fn Time::set_relative_speed_f64(
  self : Time[Virtual],
  speed : Double,
) -> Time[Virtual] {
  if speed.is_nan() || speed.is_inf() {
    abort("tried to go infinitely fast")
  }
  if speed < 0.0 {
    abort("tried to go back in time")
  }
  let context = self.context()
  { ..self, context: { ..context, relative_speed: speed } }
}

///|
pub fn Time::set_max_delta(
  self : Time[Virtual],
  max_delta : @core.Duration,
) -> Time[Virtual] {
  if max_delta.is_zero() {
    abort("tried to set max delta to zero")
  }
  let context = self.context()
  { ..self, context: { ..context, max_delta, } }
}

///|
pub fn Time::set_max_delta_seconds(
  self : Time[Virtual],
  max_delta_seconds : Float,
) -> Time[Virtual] {
  self.set_max_delta(@core.Duration::from_secs_f32(max_delta_seconds))
}

///|
pub fn Time::pause(self : Time[Virtual]) -> Time[Virtual] {
  let context = self.context()
  { ..self, context: { ..context, paused: true } }
}

///|
pub fn Time::unpause(self : Time[Virtual]) -> Time[Virtual] {
  let context = self.context()
  { ..self, context: { ..context, paused: false } }
}

///|
pub fn Time::toggle(self : Time[Virtual]) -> Time[Virtual] {
  let context = self.context()
  { ..self, context: { ..context, paused: !context.paused } }
}

///|
pub fn Time::advance_with_raw_delta(
  self : Time[Virtual],
  raw_delta : @core.Duration,
) -> Time[Virtual] {
  let context = self.context()
  let clamped_raw_delta = if raw_delta.as_nanos() > context.max_delta.as_nanos() {
    context.max_delta
  } else {
    raw_delta
  }
  let effective_speed = if context.paused {
    0.0
  } else {
    context.relative_speed
  }
  let delta = if effective_speed == 1.0 {
    clamped_raw_delta
  } else {
    clamped_raw_delta.mul_f64(effective_speed)
  }
  { ..self.advance_by(delta), context: { ..context, effective_speed, } }
}

///|
pub fn update_virtual_time(
  virtual_time : Time[Virtual],
  real_time : Time[Real],
) -> Time[Virtual] {
  virtual_time.advance_with_raw_delta(real_time.delta())
}

///|
fn world_virtual_or_default(world : @ecs.World) -> Time[Virtual] {
  world_time_resource_or_default(world, virtual_time_resource_key(), fn() {
    Time::default()
  })
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
