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
  elapsed_seconds : Float
  paused : Bool
}

///|
pub fn Stopwatch::new() -> Stopwatch {
  Stopwatch::{ elapsed_seconds: 0.0F, paused: false }
}

///|
pub fn Stopwatch::elapsed_seconds(self : Stopwatch) -> Float {
  self.elapsed_seconds
}

///|
pub fn Stopwatch::set_elapsed_seconds(
  self : Stopwatch,
  elapsed_seconds : Float,
) -> Stopwatch {
  Stopwatch::{
    ..self,
    elapsed_seconds: if elapsed_seconds < 0.0F {
      0.0F
    } else {
      elapsed_seconds
    },
  }
}

///|
pub fn Stopwatch::tick(self : Stopwatch, delta_seconds : Float) -> Stopwatch {
  if self.paused || delta_seconds <= 0.0F {
    self
  } else {
    Stopwatch::{ ..self, elapsed_seconds: self.elapsed_seconds + delta_seconds }
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
  Stopwatch::{ ..self, elapsed_seconds: 0.0F }
}
