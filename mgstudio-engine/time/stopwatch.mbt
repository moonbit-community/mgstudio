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
pub struct Stopwatch {
  elapsed : @core.Duration
  paused : Bool
} derive(Eq, Debug)

///|
pub fn Stopwatch::new() -> Stopwatch {
  Stopwatch::{ elapsed: @core.Duration::zero(), paused: false }
}

///|
pub fn Stopwatch::elapsed(self : Stopwatch) -> @core.Duration {
  self.elapsed
}

///|
pub fn Stopwatch::elapsed_secs(self : Stopwatch) -> Float {
  self.elapsed.as_secs_f32()
}

///|
pub fn Stopwatch::elapsed_secs_f64(self : Stopwatch) -> Double {
  self.elapsed.as_secs_f64()
}

///|
pub fn Stopwatch::elapsed_seconds(self : Stopwatch) -> Float {
  self.elapsed_secs()
}

///|
pub fn Stopwatch::set_elapsed(
  self : Stopwatch,
  elapsed : @core.Duration,
) -> Stopwatch {
  Stopwatch::{ ..self, elapsed, }
}

///|
pub fn Stopwatch::set_elapsed_seconds(
  self : Stopwatch,
  elapsed_seconds : Float,
) -> Stopwatch {
  self.set_elapsed(@core.Duration::from_secs_f32(elapsed_seconds))
}

///|
pub fn Stopwatch::tick(self : Stopwatch, delta : @core.Duration) -> Stopwatch {
  if self.paused || delta.is_zero() {
    self
  } else {
    Stopwatch::{ ..self, elapsed: self.elapsed.saturating_add(delta) }
  }
}

///|
pub fn Stopwatch::pause(self : Stopwatch) -> Stopwatch {
  Stopwatch::{ ..self, paused: true }
}

///|
pub fn Stopwatch::unpause(self : Stopwatch) -> Stopwatch {
  Stopwatch::{ ..self, paused: false }
}

///|
pub fn Stopwatch::is_paused(self : Stopwatch) -> Bool {
  self.paused
}

///|
pub fn Stopwatch::reset(self : Stopwatch) -> Stopwatch {
  Stopwatch::{ ..self, elapsed: @core.Duration::zero() }
}
