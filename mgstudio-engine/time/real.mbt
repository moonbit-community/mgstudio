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
  startup : @core.Instant
  first_update : @core.Instant?
  last_update : @core.Instant?
}

///|
pub impl Default for Real with default() {
  { startup: @core.Instant::now(), first_update: None, last_update: None }
}

///|
pub fn Time::new(startup : @core.Instant) -> Time[Real] {
  Time::new_with({ ..Real::default(), startup, })
}

///|
pub fn Time::update(self : Time[Real]) -> Time[Real] {
  self.update_with_instant(host_time_now_instant())
}

///|
pub fn Time::update_with_duration(
  self : Time[Real],
  duration : @core.Duration,
) -> Time[Real] {
  let context = self.context()
  let last_update = match context.last_update {
    Some(last_update) => last_update
    None => context.startup
  }
  self.update_with_instant(last_update.saturating_add(duration))
}

///|
pub fn Time::update_with_instant(
  self : Time[Real],
  instant : @core.Instant,
) -> Time[Real] {
  let context = self.context()
  match context.last_update {
    None =>
      {
        ..self,
        context: {
          ..context,
          first_update: Some(instant),
          last_update: Some(instant),
        },
      }
    Some(last_update) =>
      { ..self, context: { ..context, last_update: Some(instant) } }.advance_by(
        instant.saturating_duration_since(last_update),
      )
  }
}

///|
pub fn Time::startup(self : Time[Real]) -> @core.Instant {
  self.context().startup
}

///|
pub fn Time::startup_seconds(self : Time[Real]) -> Float {
  self.startup().as_secs_f32()
}

///|
pub fn Time::first_update(self : Time[Real]) -> @core.Instant? {
  self.context().first_update
}

///|
pub fn Time::first_update_seconds(self : Time[Real]) -> Float? {
  match self.first_update() {
    Some(instant) => Some(instant.as_secs_f32())
    None => None
  }
}

///|
pub fn Time::last_update(self : Time[Real]) -> @core.Instant? {
  self.context().last_update
}

///|
pub fn Time::last_update_seconds(self : Time[Real]) -> Float? {
  match self.last_update() {
    Some(instant) => Some(instant.as_secs_f32())
    None => None
  }
}

///|
fn world_real_or_default(world : @ecs.World) -> Time[Real] {
  world_time_resource_or_default(world, real_time_resource_key(), fn() {
    Time::default()
  })
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
