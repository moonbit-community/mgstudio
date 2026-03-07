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
  startup : @core.Instant
  first_update : @core.Instant?
  last_update : @core.Instant?
}

///|
pub fn Real::new(startup : @core.Instant) -> Real {
  Real::{ time: Time::new(), startup, first_update: None, last_update: None }
}

///|
pub fn Real::default() -> Real {
  Real::new(@core.Instant::from_millis(0L))
}

///|
pub fn Real::update(self : Real) -> Real {
  self.update_with_instant(host_time_now_instant())
}

///|
pub fn Real::update_with_duration(
  self : Real,
  duration : @core.Duration,
) -> Real {
  let last_update = match self.last_update {
    Some(last_update) => last_update
    None => self.startup
  }
  self.update_with_instant(last_update.saturating_add(duration))
}

///|
pub fn Real::update_with_instant(self : Real, instant : @core.Instant) -> Real {
  match self.last_update {
    None =>
      Real::{ ..self, first_update: Some(instant), last_update: Some(instant) }
    Some(last_update) =>
      Real::{
        ..self,
        time: self.time.advance_by(
          instant.saturating_duration_since(last_update),
        ),
        last_update: Some(instant),
      }
  }
}

///|
pub fn Real::startup(self : Real) -> @core.Instant {
  self.startup
}

///|
pub fn Real::startup_seconds(self : Real) -> Float {
  self.startup.as_secs_f32()
}

///|
pub fn Real::first_update(self : Real) -> @core.Instant? {
  self.first_update
}

///|
pub fn Real::first_update_seconds(self : Real) -> Float? {
  match self.first_update {
    Some(instant) => Some(instant.as_secs_f32())
    None => None
  }
}

///|
pub fn Real::last_update(self : Real) -> @core.Instant? {
  self.last_update
}

///|
pub fn Real::last_update_seconds(self : Real) -> Float? {
  match self.last_update {
    Some(instant) => Some(instant.as_secs_f32())
    None => None
  }
}

///|
pub fn Real::delta(self : Real) -> @core.Duration {
  time_delta_raw(self.time)
}

///|
pub fn Real::delta_seconds(self : Real) -> Float {
  time_delta_seconds_raw(self.time)
}

///|
pub fn Real::elapsed(self : Real) -> @core.Duration {
  time_elapsed_raw(self.time)
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
fn world_real_or_default(world : @ecs.World) -> Real {
  world_time_resource_or_default(world, real_resource_key, Real::default)
}

///|
pub fn time_real_delta() -> @core.Duration {
  world_real_or_default(current_time_world_abort_missing()).delta()
}

///|
pub fn time_real_delta_seconds() -> Float {
  world_real_or_default(current_time_world_abort_missing()).delta_seconds()
}

///|
pub fn time_real_elapsed() -> @core.Duration {
  world_real_or_default(current_time_world_abort_missing()).elapsed()
}

///|
pub fn time_real_elapsed_seconds() -> Float {
  world_real_or_default(current_time_world_abort_missing()).elapsed_seconds()
}
