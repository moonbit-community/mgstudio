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

///|
pub struct Time {
  mut delta_seconds : Float
  mut elapsed_seconds : Float
  mut last_ticks : Float
}

///|
const MIN_TIMER_DURATION : Float = 0.000001F

///|
pub(all) enum TimerMode {
  Once
  Repeating
}

///|
pub struct Timer {
  duration_seconds : Float
  elapsed_seconds : Float
  mode : TimerMode
  paused : Bool
  just_finished_flag : Bool
  finished_flag : Bool
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
pub fn Timer::from_seconds(seconds : Float, mode : TimerMode) -> Timer {
  Timer::{
    duration_seconds: timer_safe_duration(seconds),
    elapsed_seconds: 0.0F,
    mode,
    paused: false,
    just_finished_flag: false,
    finished_flag: false,
  }
}

///|
pub fn Timer::tick(self : Timer, delta_seconds : Float) -> Timer {
  if self.paused || delta_seconds <= 0.0F {
    return Timer::{ ..self, just_finished_flag: false }
  }

  let duration = timer_safe_duration(self.duration_seconds)
  let total = self.elapsed_seconds + delta_seconds

  match self.mode {
    Once => {
      let finished = total >= duration
      Timer::{
        ..self,
        duration_seconds: duration,
        elapsed_seconds: if finished {
          duration
        } else {
          total
        },
        just_finished_flag: !self.finished_flag && finished,
        finished_flag: finished,
      }
    }
    Repeating =>
      if total >= duration {
        let mut wrapped = total
        while wrapped >= duration {
          wrapped = wrapped - duration
        }
        Timer::{
          ..self,
          duration_seconds: duration,
          elapsed_seconds: wrapped,
          just_finished_flag: true,
          finished_flag: true,
        }
      } else {
        Timer::{
          ..self,
          duration_seconds: duration,
          elapsed_seconds: total,
          just_finished_flag: false,
          finished_flag: false,
        }
      }
  }
}

///|
pub fn Timer::pause(self : Timer) -> Timer {
  Timer::{ ..self, paused: true, just_finished_flag: false }
}

///|
pub fn Timer::unpause(self : Timer) -> Timer {
  Timer::{ ..self, paused: false }
}

///|
pub fn Timer::toggle(self : Timer) -> Timer {
  if self.paused {
    self.unpause()
  } else {
    self.pause()
  }
}

///|
pub fn Timer::is_paused(self : Timer) -> Bool {
  self.paused
}

///|
pub fn Timer::just_finished(self : Timer) -> Bool {
  self.just_finished_flag
}

///|
pub fn Timer::is_finished(self : Timer) -> Bool {
  self.finished_flag
}

///|
pub fn Timer::fraction(self : Timer) -> Float {
  timer_clampf(
    self.elapsed_seconds / timer_safe_duration(self.duration_seconds),
    0.0F,
    1.0F,
  )
}

///|
let time_state : Ref[Time] = @ref.new(Time::{
  delta_seconds: 0.0F,
  elapsed_seconds: 0.0F,
  last_ticks: 0.0F,
})

///|
pub fn host_time_now() -> Float = "mgstudio_host" "time_now"

///|
pub fn time_update() -> Unit {
  let now = host_time_now()
  if time_state.val.last_ticks == 0.0F {
    time_state.val.last_ticks = now
    time_state.val.delta_seconds = 0.0F
    time_state.val.elapsed_seconds = 0.0F
    return
  }
  let delta_ms = now - time_state.val.last_ticks
  let delta_secs = if delta_ms > 0.0F { delta_ms / 1000.0F } else { 0.0F }
  time_state.val.delta_seconds = delta_secs
  time_state.val.elapsed_seconds = time_state.val.elapsed_seconds + delta_secs
  time_state.val.last_ticks = now
}

///|
pub fn time_delta_seconds() -> Float {
  time_state.val.delta_seconds
}

///|
pub fn time_elapsed_seconds() -> Float {
  time_state.val.elapsed_seconds
}

///|
pub fn[W] time_system(_world : W) -> Unit {
  time_update()
}

///|
pub fn[W] time_plugin(app : @app.App[W]) -> @app.App[W] {
  @app.set_delta_seconds_provider(fn() { time_delta_seconds() })
  app.add_pre_update_system(time_system)
}
