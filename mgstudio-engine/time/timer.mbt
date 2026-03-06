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
const MIN_TIMER_DURATION : Float = 0.000001F

///|
pub(all) enum TimerMode {
  Once
  Repeating
}

///|
pub struct Timer {
  stopwatch : Stopwatch
  duration_seconds : Float
  mode : TimerMode
  finished : Bool
  times_finished_this_tick : Int
}

///|
fn timer_safe_duration(seconds : Float) -> Float {
  if seconds <= 0.0F {
    MIN_TIMER_DURATION
  } else {
    seconds
  }
}

///|
fn timer_clampf(value : Float, min_value : Float, max_value : Float) -> Float {
  if value < min_value {
    min_value
  } else if value > max_value {
    max_value
  } else {
    value
  }
}

///|
pub fn Timer::new(duration_seconds : Float, mode : TimerMode) -> Timer {
  Timer::{
    stopwatch: Stopwatch::new(),
    duration_seconds: timer_safe_duration(duration_seconds),
    mode,
    finished: false,
    times_finished_this_tick: 0,
  }
}

///|
pub fn Timer::from_seconds(seconds : Float, mode : TimerMode) -> Timer {
  Timer::new(seconds, mode)
}

///|
pub fn Timer::tick(self : Timer, delta_seconds : Float) -> Timer {
  if self.stopwatch.is_paused() || delta_seconds <= 0.0F {
    return Timer::{ ..self, times_finished_this_tick: 0 }
  }

  let duration_seconds = timer_safe_duration(self.duration_seconds)
  let stopwatch = self.stopwatch.tick(delta_seconds)
  let elapsed_seconds = stopwatch.elapsed_seconds()

  match self.mode {
    Once => {
      let finished = elapsed_seconds >= duration_seconds
      Timer::{
        ..self,
        stopwatch: if finished {
          stopwatch.set_elapsed_seconds(duration_seconds)
        } else {
          stopwatch
        },
        duration_seconds,
        finished,
        times_finished_this_tick: if !self.finished && finished {
          1
        } else {
          0
        },
      }
    }
    Repeating =>
      if elapsed_seconds >= duration_seconds {
        let mut wrapped_seconds = elapsed_seconds
        let mut times_finished = 0
        while wrapped_seconds >= duration_seconds {
          wrapped_seconds = wrapped_seconds - duration_seconds
          times_finished = times_finished + 1
        }
        Timer::{
          ..self,
          stopwatch: stopwatch.set_elapsed_seconds(wrapped_seconds),
          duration_seconds,
          finished: times_finished > 0,
          times_finished_this_tick: times_finished,
        }
      } else {
        Timer::{
          ..self,
          stopwatch,
          duration_seconds,
          finished: false,
          times_finished_this_tick: 0,
        }
      }
  }
}

///|
pub fn Timer::pause(self : Timer) -> Timer {
  Timer::{
    ..self,
    stopwatch: self.stopwatch.pause(),
    times_finished_this_tick: 0,
  }
}

///|
pub fn Timer::unpause(self : Timer) -> Timer {
  Timer::{ ..self, stopwatch: self.stopwatch.unpause() }
}

///|
pub fn Timer::toggle(self : Timer) -> Timer {
  if self.is_paused() {
    self.unpause()
  } else {
    self.pause()
  }
}

///|
pub fn Timer::reset(self : Timer) -> Timer {
  Timer::{
    ..self,
    stopwatch: self.stopwatch.reset(),
    finished: false,
    times_finished_this_tick: 0,
  }
}

///|
pub fn Timer::is_paused(self : Timer) -> Bool {
  self.stopwatch.is_paused()
}

///|
pub fn Timer::just_finished(self : Timer) -> Bool {
  self.times_finished_this_tick > 0
}

///|
pub fn Timer::is_finished(self : Timer) -> Bool {
  self.finished
}

///|
pub fn Timer::elapsed_seconds(self : Timer) -> Float {
  self.stopwatch.elapsed_seconds()
}

///|
pub fn Timer::duration_seconds(self : Timer) -> Float {
  self.duration_seconds
}

///|
pub fn Timer::set_duration_seconds(
  self : Timer,
  duration_seconds : Float,
) -> Timer {
  Timer::{ ..self, duration_seconds: timer_safe_duration(duration_seconds) }
}

///|
pub fn Timer::remaining_seconds(self : Timer) -> Float {
  let remaining = self.duration_seconds - self.elapsed_seconds()
  if remaining < 0.0F {
    0.0F
  } else {
    remaining
  }
}

///|
pub fn Timer::times_finished_this_tick(self : Timer) -> Int {
  self.times_finished_this_tick
}

///|
pub fn Timer::fraction(self : Timer) -> Float {
  timer_clampf(
    self.elapsed_seconds() / timer_safe_duration(self.duration_seconds),
    0.0F,
    1.0F,
  )
}
