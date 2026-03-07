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
const DEFAULT_FIXED_TIMESTEP_SECONDS : Float = 0.015625F

///|
pub struct Fixed {
  time : Time
  timestep_seconds : Float
  overstep_seconds : Float
}

///|
pub fn Fixed::new() -> Fixed {
  Fixed::{
    time: Time::new(),
    timestep_seconds: DEFAULT_FIXED_TIMESTEP_SECONDS,
    overstep_seconds: 0.0F,
  }
}

///|
pub fn Fixed::default() -> Fixed {
  Fixed::new()
}

///|
pub fn Fixed::from_duration_seconds(timestep_seconds : Float) -> Fixed {
  Fixed::new().set_timestep_seconds(timestep_seconds)
}

///|
pub fn Fixed::from_seconds(seconds : Float) -> Fixed {
  Fixed::from_duration_seconds(seconds)
}

///|
pub fn Fixed::from_hz(hz : Float) -> Fixed {
  if hz.is_nan() || hz.is_inf() {
    abort("Hz is infinite")
  }
  if hz <= 0.0F {
    abort("Hz less than or equal to zero")
  }
  Fixed::from_seconds(1.0F / hz)
}

///|
pub fn Fixed::delta_seconds(self : Fixed) -> Float {
  time_delta_seconds_raw(self.time)
}

///|
pub fn Fixed::elapsed_seconds(self : Fixed) -> Float {
  time_elapsed_seconds_raw(self.time)
}

///|
pub fn Fixed::timestep_seconds(self : Fixed) -> Float {
  self.timestep_seconds
}

///|
pub fn Fixed::set_timestep_seconds(self : Fixed, seconds : Float) -> Fixed {
  if seconds.is_nan() || seconds.is_inf() {
    abort("seconds is infinite")
  }
  if seconds <= 0.0F {
    abort("attempted to set fixed timestep to zero")
  }
  Fixed::{ ..self, timestep_seconds: seconds }
}

///|
pub fn Fixed::set_timestep_hz(self : Fixed, hz : Float) -> Fixed {
  if hz.is_nan() || hz.is_inf() {
    abort("Hz is infinite")
  }
  if hz <= 0.0F {
    abort("Hz less than or equal to zero")
  }
  self.set_timestep_seconds(1.0F / hz)
}

///|
pub fn Fixed::overstep_seconds(self : Fixed) -> Float {
  self.overstep_seconds
}

///|
pub fn Fixed::accumulate_overstep(self : Fixed, delta_seconds : Float) -> Fixed {
  Fixed::{
    ..self,
    overstep_seconds: self.overstep_seconds +
    time_non_negative_seconds(delta_seconds),
  }
}

///|
pub fn Fixed::discard_overstep(self : Fixed, discard_seconds : Float) -> Fixed {
  let overstep_seconds = self.overstep_seconds -
    time_non_negative_seconds(discard_seconds)
  Fixed::{
    ..self,
    overstep_seconds: if overstep_seconds < 0.0F {
      0.0F
    } else {
      overstep_seconds
    },
  }
}

///|
pub fn Fixed::overstep_fraction(self : Fixed) -> Float {
  if self.timestep_seconds <= 0.0F {
    0.0F
  } else {
    self.overstep_seconds / self.timestep_seconds
  }
}

///|
pub fn Fixed::overstep_fraction_f64(self : Fixed) -> Float {
  self.overstep_fraction()
}

///|
pub fn Fixed::as_generic(self : Fixed) -> Time {
  self.time.as_generic()
}

///|
pub fn Fixed::expend(self : Fixed) -> Fixed? {
  let remaining_overstep = self.overstep_seconds - self.timestep_seconds
  if remaining_overstep < 0.0F {
    None
  } else {
    Some(Fixed::{
      ..self,
      time: self.time.advance_by(self.timestep_seconds),
      overstep_seconds: remaining_overstep,
    })
  }
}

///|
priv struct FixedFrameState {
  mut did_run_this_frame : Bool
  mut steps_ran_this_frame : Int
}

///|
let fixed_frame_state : Ref[FixedFrameState] = Ref::new(FixedFrameState::{
  did_run_this_frame: false,
  steps_ran_this_frame: 0,
})

///|
fn time_fixed_begin_frame() -> Unit {
  fixed_frame_state.val.did_run_this_frame = false
  fixed_frame_state.val.steps_ran_this_frame = 0
}

///|
fn time_fixed_mark_step() -> Unit {
  fixed_frame_state.val.did_run_this_frame = true
  fixed_frame_state.val.steps_ran_this_frame = fixed_frame_state.val.steps_ran_this_frame +
    1
}

///|
pub fn time_run_fixed_main_schedule(world : @ecs.World) -> Unit {
  ensure_time_resources(world)
  time_fixed_begin_frame()
  let delta_seconds = world_virtual_or_default(world).delta_seconds()
  let accumulated_fixed = world_fixed_or_default(world).accumulate_overstep(
    delta_seconds,
  )
  sync_world_time_resource(
    world,
    fixed_resource_key,
    accumulated_fixed,
    world.increment_change_tick(),
  )
  while true {
    let current_fixed = world_fixed_or_default(world)
    match current_fixed.expend() {
      Some(next_fixed) => {
        let change_tick = world.increment_change_tick()
        sync_world_time_resource(
          world, fixed_resource_key, next_fixed, change_tick,
        )
        time_sync_generic_time(world, change_tick, next_fixed.as_generic())
        time_fixed_mark_step()
        @app.run_current_fixed_main_schedule(world)
      }
      None => break
    }
  }
  time_restore_virtual_as_generic(world)
}

///|
pub fn time_fixed_did_run_this_frame() -> Bool {
  fixed_frame_state.val.did_run_this_frame
}

///|
pub fn time_fixed_steps_ran_this_frame() -> Int {
  fixed_frame_state.val.steps_ran_this_frame
}

///|
fn world_fixed_or_default(world : @ecs.World) -> Fixed {
  world_time_resource_or_default(world, fixed_resource_key, Fixed::new)
}

///|
pub fn time_fixed_delta_seconds() -> Float {
  world_fixed_or_default(current_time_world_abort_missing()).delta_seconds()
}

///|
pub fn time_fixed_elapsed_seconds() -> Float {
  world_fixed_or_default(current_time_world_abort_missing()).elapsed_seconds()
}

///|
pub fn time_fixed_timestep_seconds() -> Float {
  world_fixed_or_default(current_time_world_abort_missing()).timestep_seconds()
}

///|
pub fn time_fixed_overstep_seconds() -> Float {
  world_fixed_or_default(current_time_world_abort_missing()).overstep_seconds()
}

///|
pub fn time_fixed_overstep_fraction() -> Float {
  world_fixed_or_default(current_time_world_abort_missing()).overstep_fraction()
}
