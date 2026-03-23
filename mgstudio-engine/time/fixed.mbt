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
  timestep : @core.Duration
  overstep : @core.Duration
}

///|
pub impl Default for Fixed with default() {
  { timestep: default_fixed_timestep, overstep: @core.Duration::zero() }
}

///|
pub fn Time::from_duration(timestep : @core.Duration) -> Time[Fixed] {
  let fixed_time : Time[Fixed] = Time::default()
  fixed_time.set_timestep(timestep)
}

///|
pub fn Time::from_duration_seconds(timestep_seconds : Float) -> Time[Fixed] {
  Time::from_duration(@core.Duration::from_secs_f32(timestep_seconds))
}

///|
pub fn Time::from_seconds(seconds : Float) -> Time[Fixed] {
  Time::from_duration_seconds(seconds)
}

///|
pub fn Time::from_hz(hz : Float) -> Time[Fixed] {
  if hz.is_nan() || hz.is_inf() {
    abort("Hz is infinite")
  }
  if hz <= 0.0F {
    abort("Hz less than or equal to zero")
  }
  Time::from_seconds(1.0F / hz)
}

///|
pub fn Time::timestep(self : Time[Fixed]) -> @core.Duration {
  self.context().timestep
}

///|
pub fn Time::timestep_seconds(self : Time[Fixed]) -> Float {
  self.timestep().as_secs_f32()
}

///|
pub fn Time::set_timestep(
  self : Time[Fixed],
  timestep : @core.Duration,
) -> Time[Fixed] {
  if timestep.is_zero() {
    abort("attempted to set fixed timestep to zero")
  }
  let context = self.context()
  { ..self, context: { ..context, timestep, } }
}

///|
pub fn Time::set_timestep_seconds(
  self : Time[Fixed],
  seconds : Float,
) -> Time[Fixed] {
  if seconds.is_nan() || seconds.is_inf() {
    abort("seconds is infinite")
  }
  if seconds <= 0.0F {
    abort("seconds less than or equal to zero")
  }
  self.set_timestep(@core.Duration::from_secs_f32(seconds))
}

///|
pub fn Time::set_timestep_hz(self : Time[Fixed], hz : Float) -> Time[Fixed] {
  if hz.is_nan() || hz.is_inf() {
    abort("Hz is infinite")
  }
  if hz <= 0.0F {
    abort("Hz less than or equal to zero")
  }
  self.set_timestep_seconds(1.0F / hz)
}

///|
pub fn Time::overstep(self : Time[Fixed]) -> @core.Duration {
  self.context().overstep
}

///|
pub fn Time::overstep_seconds(self : Time[Fixed]) -> Float {
  self.overstep().as_secs_f32()
}

///|
pub fn Time::accumulate_overstep(
  self : Time[Fixed],
  delta : @core.Duration,
) -> Time[Fixed] {
  let context = self.context()
  {
    ..self,
    context: { ..context, overstep: context.overstep.saturating_add(delta) },
  }
}

///|
pub fn Time::discard_overstep(
  self : Time[Fixed],
  discard : @core.Duration,
) -> Time[Fixed] {
  let context = self.context()
  {
    ..self,
    context: { ..context, overstep: context.overstep.saturating_sub(discard) },
  }
}

///|
pub fn Time::overstep_fraction(self : Time[Fixed]) -> Float {
  self.overstep().as_secs_f32() / self.timestep().as_secs_f32()
}

///|
pub fn Time::overstep_fraction_f64(self : Time[Fixed]) -> Double {
  self.overstep().as_secs_f64() / self.timestep().as_secs_f64()
}

///|
pub fn Time::expend(self : Time[Fixed]) -> Time[Fixed]? {
  let context = self.context()
  match context.overstep.checked_sub(context.timestep) {
    Some(remaining_overstep) =>
      Some(
        { ..self, context: { ..context, overstep: remaining_overstep } }.advance_by(
          context.timestep,
        ),
      )
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
    fixed_time_resource_key(),
    accumulated_fixed,
    world.advance_sequence(),
  )
  while true {
    let current_fixed = world_fixed_or_default(world)
    match current_fixed.expend() {
      Some(next_fixed) => {
        let sequence = world.advance_sequence()
        sync_world_time_resource(
          world,
          fixed_time_resource_key(),
          next_fixed,
          sequence,
        )
        time_sync_generic_time(world, sequence, next_fixed.as_generic())
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
fn world_fixed_or_default(world : @ecs.World) -> Time[Fixed] {
  world_time_resource_or_default(world, fixed_time_resource_key(), fn() {
    Time::default()
  })
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
