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
#valtype
pub(all) enum TimerMode {
  Once
  Repeating
} derive(Eq, Debug)

///|
#valtype
pub struct Timer {
  stopwatch_elapsed_nanos : Int64
  stopwatch_paused : Bool
  duration_nanos : Int64
  mode_repeating : Bool
  finished : Bool
  times_finished_this_tick : Int
} derive(Eq, Debug)

///|
fn timer_fraction(elapsed : @core.Duration, duration : @core.Duration) -> Float {
  let duration_nanos = duration.as_nanos()
  if duration_nanos <= 0L {
    1.0F
  } else {
    let fraction = elapsed.as_secs_f64() / duration.as_secs_f64()
    if fraction < 0.0 {
      0.0F
    } else if fraction > 1.0 {
      1.0F
    } else {
      Float::from_double(fraction)
    }
  }
}

///|
fn timer_is_elapsed(
  elapsed : @core.Duration,
  duration : @core.Duration,
) -> Bool {
  elapsed.as_nanos() >= duration.as_nanos()
}

///|
pub fn Timer::new(duration : @core.Duration, mode : TimerMode) -> Timer {
  Timer::{
    stopwatch_elapsed_nanos: 0L,
    stopwatch_paused: false,
    duration_nanos: duration.as_nanos(),
    mode_repeating: mode == Repeating,
    finished: false,
    times_finished_this_tick: 0,
  }
}

///|
pub fn Timer::from_seconds(seconds : Float, mode : TimerMode) -> Timer {
  Timer::new(@core.Duration::from_secs_f32(seconds), mode)
}

///|
pub fn Timer::tick(self : Timer, delta : @core.Duration) -> Timer {
  if self.stopwatch_paused {
    return Timer::{
      ..self,
      times_finished_this_tick: 0,
      finished: if self.mode_repeating {
        false
      } else {
        self.finished
      },
    }
  }

  if !self.mode_repeating && self.finished {
    return Timer::{ ..self, times_finished_this_tick: 0 }
  }

  let stopwatch = Stopwatch::{
    elapsed_nanos: self.stopwatch_elapsed_nanos,
    paused: self.stopwatch_paused,
  }.tick(delta)
  let elapsed = stopwatch.elapsed()
  let duration = self.duration()
  let finished = timer_is_elapsed(elapsed, duration)

  if !finished {
    return Timer::{
      ..self,
      stopwatch_elapsed_nanos: elapsed.as_nanos(),
      finished: false,
      times_finished_this_tick: 0,
    }
  }

  if self.mode_repeating {
    let duration_nanos = duration.as_nanos()
    let elapsed_nanos = elapsed.as_nanos()
    let times_finished = if duration_nanos <= 0L {
      2_147_483_647
    } else {
      (elapsed_nanos / duration_nanos).to_int()
    }
    let wrapped = if duration_nanos <= 0L {
      @core.Duration::zero()
    } else {
      @core.Duration::from_nanos(elapsed_nanos % duration_nanos)
    }
    Timer::{
      ..self,
      stopwatch_elapsed_nanos: wrapped.as_nanos(),
      finished: times_finished > 0,
      times_finished_this_tick: times_finished,
    }
  } else {
    Timer::{
      ..self,
      stopwatch_elapsed_nanos: duration.as_nanos(),
      finished: true,
      times_finished_this_tick: 1,
    }
  }
}

///|
pub fn Timer::pause(self : Timer) -> Timer {
  Timer::{ ..self, stopwatch_paused: true, times_finished_this_tick: 0 }
}

///|
pub fn Timer::unpause(self : Timer) -> Timer {
  Timer::{ ..self, stopwatch_paused: false }
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
    stopwatch_elapsed_nanos: 0L,
    finished: false,
    times_finished_this_tick: 0,
  }
}

///|
pub fn Timer::mode(self : Timer) -> TimerMode {
  if self.mode_repeating {
    Repeating
  } else {
    Once
  }
}

///|
pub fn Timer::set_mode(self : Timer, mode : TimerMode) -> Timer {
  let mode_repeating = mode == Repeating
  if !self.mode_repeating && mode_repeating && self.finished {
    Timer::{
      ..self,
      mode_repeating,
      stopwatch_elapsed_nanos: 0L,
      finished: false,
      times_finished_this_tick: 0,
    }
  } else {
    Timer::{ ..self, mode_repeating, }
  }
}

///|
pub fn Timer::is_paused(self : Timer) -> Bool {
  self.stopwatch_paused
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
pub fn Timer::elapsed(self : Timer) -> @core.Duration {
  @core.Duration::from_nanos(self.stopwatch_elapsed_nanos)
}

///|
pub fn Timer::elapsed_secs(self : Timer) -> Float {
  self.elapsed().as_secs_f32()
}

///|
pub fn Timer::elapsed_secs_f64(self : Timer) -> Double {
  self.elapsed().as_secs_f64()
}

///|
pub fn Timer::elapsed_seconds(self : Timer) -> Float {
  self.elapsed_secs()
}

///|
pub fn Timer::set_elapsed(self : Timer, elapsed : @core.Duration) -> Timer {
  Timer::{ ..self, stopwatch_elapsed_nanos: elapsed.as_nanos() }
}

///|
pub fn Timer::duration(self : Timer) -> @core.Duration {
  @core.Duration::from_nanos(self.duration_nanos)
}

///|
pub fn Timer::duration_seconds(self : Timer) -> Float {
  self.duration().as_secs_f32()
}

///|
pub fn Timer::set_duration(self : Timer, duration : @core.Duration) -> Timer {
  Timer::{ ..self, duration_nanos: duration.as_nanos() }
}

///|
pub fn Timer::set_duration_seconds(
  self : Timer,
  duration_seconds : Float,
) -> Timer {
  self.set_duration(@core.Duration::from_secs_f32(duration_seconds))
}

///|
pub fn Timer::finish(self : Timer) -> Timer {
  self.tick(self.remaining())
}

///|
pub fn Timer::almost_finish(self : Timer) -> Timer {
  let remaining = self.remaining()
  if remaining.is_zero() {
    self
  } else {
    self.tick(remaining.saturating_sub(@core.Duration::from_nanos(1L)))
  }
}

///|
pub fn Timer::remaining(self : Timer) -> @core.Duration {
  self.duration().saturating_sub(self.elapsed())
}

///|
pub fn Timer::remaining_secs(self : Timer) -> Float {
  self.remaining().as_secs_f32()
}

///|
pub fn Timer::remaining_seconds(self : Timer) -> Float {
  self.remaining_secs()
}

///|
pub fn Timer::times_finished_this_tick(self : Timer) -> Int {
  self.times_finished_this_tick
}

///|
pub fn Timer::fraction(self : Timer) -> Float {
  timer_fraction(self.elapsed(), self.duration())
}

///|
pub fn Timer::fraction_remaining(self : Timer) -> Float {
  1.0F - self.fraction()
}
