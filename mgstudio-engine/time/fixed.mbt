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
let default_fixed_timestep : @core.Duration = @core.Duration::from_micros(
  15_625L,
)

///|
pub struct Fixed {
  time : Time
  timestep : @core.Duration
  overstep : @core.Duration
}

///|
pub fn Fixed::new() -> Fixed {
  Fixed::{
    time: Time::new(),
    timestep: default_fixed_timestep,
    overstep: @core.Duration::zero(),
  }
}

///|
pub fn Fixed::default() -> Fixed {
  Fixed::new()
}

///|
pub fn Fixed::from_duration(timestep : @core.Duration) -> Fixed {
  Fixed::new().set_timestep(timestep)
}

///|
pub fn Fixed::from_duration_seconds(timestep_seconds : Float) -> Fixed {
  Fixed::from_duration(@core.Duration::from_secs_f32(timestep_seconds))
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
pub fn Fixed::delta(self : Fixed) -> @core.Duration {
  time_delta_raw(self.time)
}

///|
pub fn Fixed::delta_seconds(self : Fixed) -> Float {
  time_delta_seconds_raw(self.time)
}

///|
pub fn Fixed::elapsed(self : Fixed) -> @core.Duration {
  time_elapsed_raw(self.time)
}

///|
pub fn Fixed::elapsed_seconds(self : Fixed) -> Float {
  time_elapsed_seconds_raw(self.time)
}

///|
pub fn Fixed::timestep(self : Fixed) -> @core.Duration {
  self.timestep
}

///|
pub fn Fixed::timestep_seconds(self : Fixed) -> Float {
  self.timestep.as_secs_f32()
}

///|
pub fn Fixed::set_timestep(self : Fixed, timestep : @core.Duration) -> Fixed {
  if timestep.is_zero() {
    abort("attempted to set fixed timestep to zero")
  }
  Fixed::{ ..self, timestep, }
}

///|
pub fn Fixed::set_timestep_seconds(self : Fixed, seconds : Float) -> Fixed {
  if seconds.is_nan() || seconds.is_inf() {
    abort("seconds is infinite")
  }
  if seconds <= 0.0F {
    abort("seconds less than or equal to zero")
  }
  self.set_timestep(@core.Duration::from_secs_f32(seconds))
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
pub fn Fixed::overstep(self : Fixed) -> @core.Duration {
  self.overstep
}

///|
pub fn Fixed::overstep_seconds(self : Fixed) -> Float {
  self.overstep.as_secs_f32()
}

///|
pub fn Fixed::accumulate_overstep(
  self : Fixed,
  delta : @core.Duration,
) -> Fixed {
  Fixed::{ ..self, overstep: self.overstep.saturating_add(delta) }
}

///|
pub fn Fixed::discard_overstep(self : Fixed, discard : @core.Duration) -> Fixed {
  Fixed::{ ..self, overstep: self.overstep.saturating_sub(discard) }
}

///|
pub fn Fixed::overstep_fraction(self : Fixed) -> Float {
  self.overstep.as_secs_f32() / self.timestep.as_secs_f32()
}

///|
pub fn Fixed::overstep_fraction_f64(self : Fixed) -> Double {
  self.overstep.as_secs_f64() / self.timestep.as_secs_f64()
}

///|
pub fn Fixed::as_generic(self : Fixed) -> Time {
  self.time.as_generic()
}

///|
pub fn Fixed::expend(self : Fixed) -> Fixed? {
  match self.overstep.checked_sub(self.timestep) {
    Some(remaining_overstep) =>
      Some(Fixed::{
        ..self,
        time: self.time.advance_by(self.timestep),
        overstep: remaining_overstep,
      })
    None => None
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
  let delta = world_virtual_or_default(world).delta()
  let accumulated_fixed = world_fixed_or_default(world).accumulate_overstep(
    delta,
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
pub fn time_fixed_delta() -> @core.Duration {
  world_fixed_or_default(current_time_world_abort_missing()).delta()
}

///|
pub fn time_fixed_delta_seconds() -> Float {
  world_fixed_or_default(current_time_world_abort_missing()).delta_seconds()
}

///|
pub fn time_fixed_elapsed() -> @core.Duration {
  world_fixed_or_default(current_time_world_abort_missing()).elapsed()
}

///|
pub fn time_fixed_elapsed_seconds() -> Float {
  world_fixed_or_default(current_time_world_abort_missing()).elapsed_seconds()
}

///|
pub fn time_fixed_timestep() -> @core.Duration {
  world_fixed_or_default(current_time_world_abort_missing()).timestep()
}

///|
pub fn time_fixed_timestep_seconds() -> Float {
  world_fixed_or_default(current_time_world_abort_missing()).timestep_seconds()
}

///|
pub fn time_fixed_overstep() -> @core.Duration {
  world_fixed_or_default(current_time_world_abort_missing()).overstep()
}

///|
pub fn time_fixed_overstep_seconds() -> Float {
  world_fixed_or_default(current_time_world_abort_missing()).overstep_seconds()
}

///|
pub fn time_fixed_overstep_fraction() -> Float {
  world_fixed_or_default(current_time_world_abort_missing()).overstep_fraction()
}
