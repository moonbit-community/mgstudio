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
  mut real_delta_seconds : Float
  mut real_elapsed_seconds : Float
  mut virtual_delta_seconds : Float
  mut virtual_elapsed_seconds : Float
  mut virtual_relative_speed : Float
  mut virtual_max_delta_seconds : Float
  mut virtual_paused : Bool
  mut last_ticks : Float
}

///|
pub fn Time::delta_seconds(self : Time) -> Float {
  match @app.current_schedule_stage() {
    Some(@app.FixedUpdate) => @app.fixed_time_timestep_seconds()
    _ => self.virtual_delta_seconds
  }
}

///|
pub fn Time::elapsed_seconds(self : Time) -> Float {
  match @app.current_schedule_stage() {
    Some(@app.FixedUpdate) => @app.fixed_time_elapsed_seconds()
    _ => self.virtual_elapsed_seconds
  }
}

///|
const MIN_TIMER_DURATION : Float = 0.000001F

///|
const DEFAULT_VIRTUAL_MAX_DELTA_SECONDS : Float = 0.25F

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
  real_delta_seconds: 0.0F,
  real_elapsed_seconds: 0.0F,
  virtual_delta_seconds: 0.0F,
  virtual_elapsed_seconds: 0.0F,
  virtual_relative_speed: 1.0F,
  virtual_max_delta_seconds: DEFAULT_VIRTUAL_MAX_DELTA_SECONDS,
  virtual_paused: false,
  last_ticks: 0.0F,
})

///|
let time_resource : Ref[@core.Resource[Time]] = Ref::new(@core.Resource::new())

///|
pub impl @app.Resource for Time with resource() {
  time_resource.val
}

///|
pub fn host_time_now() -> Float = "mgstudio_host" "time_now"

///|
pub fn time_update() -> Unit {
  let now = host_time_now()
  if time_state.val.last_ticks == 0.0F {
    time_state.val.last_ticks = now
    time_state.val.real_delta_seconds = 0.0F
    time_state.val.real_elapsed_seconds = 0.0F
    time_state.val.virtual_delta_seconds = 0.0F
    time_state.val.virtual_elapsed_seconds = 0.0F
    return
  }
  let delta_ms = now - time_state.val.last_ticks
  let real_delta_secs = if delta_ms > 0.0F { delta_ms / 1000.0F } else { 0.0F }
  let clamped_virtual_source_delta = if real_delta_secs >
    time_state.val.virtual_max_delta_seconds {
    time_state.val.virtual_max_delta_seconds
  } else {
    real_delta_secs
  }
  let virtual_delta_secs = if time_state.val.virtual_paused {
    0.0F
  } else {
    clamped_virtual_source_delta * time_state.val.virtual_relative_speed
  }
  time_state.val.real_delta_seconds = real_delta_secs
  time_state.val.real_elapsed_seconds = time_state.val.real_elapsed_seconds +
    real_delta_secs
  time_state.val.virtual_delta_seconds = virtual_delta_secs
  time_state.val.virtual_elapsed_seconds = time_state.val.virtual_elapsed_seconds +
    virtual_delta_secs
  time_state.val.last_ticks = now
}

///|
pub fn time_delta_seconds() -> Float {
  match @app.current_schedule_stage() {
    Some(@app.FixedUpdate) => @app.fixed_time_timestep_seconds()
    _ => time_state.val.virtual_delta_seconds
  }
}

///|
pub fn time_elapsed_seconds() -> Float {
  match @app.current_schedule_stage() {
    Some(@app.FixedUpdate) => @app.fixed_time_elapsed_seconds()
    _ => time_state.val.virtual_elapsed_seconds
  }
}

///|
pub fn time_real_delta_seconds() -> Float {
  time_state.val.real_delta_seconds
}

///|
pub fn time_real_elapsed_seconds() -> Float {
  time_state.val.real_elapsed_seconds
}

///|
pub fn time_virtual_delta_seconds() -> Float {
  time_state.val.virtual_delta_seconds
}

///|
pub fn time_virtual_elapsed_seconds() -> Float {
  time_state.val.virtual_elapsed_seconds
}

///|
pub fn time_virtual_relative_speed() -> Float {
  time_state.val.virtual_relative_speed
}

///|
pub fn time_virtual_max_delta_seconds() -> Float {
  time_state.val.virtual_max_delta_seconds
}

///|
pub fn time_virtual_set_relative_speed(speed : Float) -> Unit {
  time_state.val.virtual_relative_speed = if speed < 0.0F {
    0.0F
  } else {
    speed
  }
}

///|
pub fn time_virtual_set_max_delta_seconds(max_delta_seconds : Float) -> Unit {
  if max_delta_seconds > 0.0F {
    time_state.val.virtual_max_delta_seconds = max_delta_seconds
  }
}

///|
pub fn time_virtual_pause() -> Unit {
  time_state.val.virtual_paused = true
}

///|
pub fn time_virtual_unpause() -> Unit {
  time_state.val.virtual_paused = false
}

///|
pub fn time_virtual_toggle() -> Unit {
  time_state.val.virtual_paused = !time_state.val.virtual_paused
}

///|
pub fn time_virtual_is_paused() -> Bool {
  time_state.val.virtual_paused
}

///|
pub fn time_fixed_delta_seconds() -> Float {
  @app.fixed_time_timestep_seconds()
}

///|
pub fn time_fixed_elapsed_seconds() -> Float {
  @app.fixed_time_elapsed_seconds()
}

///|
pub fn time_fixed_timestep_seconds() -> Float {
  @app.fixed_time_timestep_seconds()
}

///|
pub fn time_fixed_overstep_seconds() -> Float {
  @app.fixed_time_overstep_seconds()
}

///|
pub fn time_fixed_overstep_fraction() -> Float {
  @app.fixed_time_overstep_fraction()
}

///|
pub fn[W] time_system(_world : W) -> Unit {
  time_update()
}

///|
fn time_update_resource_system(time : @app.ResMut[Time]) -> Unit {
  time_update()
  time.get_ref().val = time_state.val
}

///|
pub fn[W] time_plugin(app : @app.App[W]) -> @app.App[W] {
  @app.set_delta_seconds_provider(fn() { time_virtual_delta_seconds() })
  app
  .insert_resource(time_state.val)
  .add_pre_update_system_param(time_update_resource_system)
}
