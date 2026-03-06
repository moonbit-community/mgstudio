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
pub struct TimePlugin {}

///|
pub fn TimePlugin::default() -> TimePlugin {
  TimePlugin::{  }
}

///|
priv struct TimeState {
  startup_seconds : Float
  mut first_update_seconds : Float?
  mut last_update_seconds : Float?
  mut real_delta_seconds : Float
  mut real_elapsed_seconds : Float
  mut virtual_delta_seconds : Float
  mut virtual_elapsed_seconds : Float
  mut virtual_relative_speed : Float
  mut virtual_effective_speed : Float
  mut virtual_max_delta_seconds : Float
  mut virtual_paused : Bool
  mut virtual_was_paused : Bool
}

///|
const DEFAULT_VIRTUAL_MAX_DELTA_SECONDS : Float = 0.25F

///|
let time_state_ref : Ref[TimeState] = @ref.new(TimeState::{
  startup_seconds: 0.0F,
  first_update_seconds: None,
  last_update_seconds: None,
  real_delta_seconds: 0.0F,
  real_elapsed_seconds: 0.0F,
  virtual_delta_seconds: 0.0F,
  virtual_elapsed_seconds: 0.0F,
  virtual_relative_speed: 1.0F,
  virtual_effective_speed: 1.0F,
  virtual_max_delta_seconds: DEFAULT_VIRTUAL_MAX_DELTA_SECONDS,
  virtual_paused: false,
  virtual_was_paused: false,
})

///|
let time_resource : Ref[@core.Resource[Time]] = Ref::new(@core.Resource::new())

///|
let real_resource : Ref[@core.Resource[Real]] = Ref::new(@core.Resource::new())

///|
let virtual_resource : Ref[@core.Resource[Virtual]] = Ref::new(
  @core.Resource::new(),
)

///|
let fixed_resource : Ref[@core.Resource[Fixed]] = Ref::new(
  @core.Resource::new(),
)

///|
pub impl @app.Resource for Time with resource() {
  time_resource.val
}

///|
pub impl @app.Resource for Real with resource() {
  real_resource.val
}

///|
pub impl @app.Resource for Virtual with resource() {
  virtual_resource.val
}

///|
pub impl @app.Resource for Fixed with resource() {
  fixed_resource.val
}

///|
pub fn host_time_now() -> Float {
  @native_time.now()
}

///|
fn time_snapshot() -> Time {
  Time::{
    delta_seconds: time_delta_seconds(),
    elapsed_seconds: time_elapsed_seconds(),
  }
}

///|
fn real_snapshot() -> Real {
  Real::{
    startup_seconds: time_state_ref.val.startup_seconds,
    first_update_seconds: time_state_ref.val.first_update_seconds,
    last_update_seconds: time_state_ref.val.last_update_seconds,
    delta_seconds: time_state_ref.val.real_delta_seconds,
    elapsed_seconds: time_state_ref.val.real_elapsed_seconds,
  }
}

///|
fn virtual_snapshot() -> Virtual {
  Virtual::{
    delta_seconds: time_state_ref.val.virtual_delta_seconds,
    elapsed_seconds: time_state_ref.val.virtual_elapsed_seconds,
    relative_speed: time_state_ref.val.virtual_relative_speed,
    effective_speed: time_state_ref.val.virtual_effective_speed,
    max_delta_seconds: time_state_ref.val.virtual_max_delta_seconds,
    paused: time_state_ref.val.virtual_paused,
    was_paused: time_state_ref.val.virtual_was_paused,
  }
}

///|
fn fixed_snapshot() -> Fixed {
  Fixed::{
    delta_seconds: time_fixed_delta_seconds(),
    elapsed_seconds: time_fixed_elapsed_seconds(),
    timestep_seconds: time_fixed_timestep_seconds(),
    overstep_seconds: time_fixed_overstep_seconds(),
  }
}

///|
fn[T] sync_resource(
  resource : @core.Resource[T],
  value : T,
  change_tick : @core.Tick,
) -> Unit {
  match resource.get_ref_mut(change_tick) {
    Some(cell) => cell.val = value
    None => resource.insert(value, change_tick)
  }
}

///|
pub fn time_update() -> Unit {
  let now = host_time_now()
  match time_state_ref.val.last_update_seconds {
    None => {
      time_state_ref.val.first_update_seconds = Some(now)
      time_state_ref.val.last_update_seconds = Some(now)
      time_state_ref.val.real_delta_seconds = 0.0F
      time_state_ref.val.virtual_delta_seconds = 0.0F
      time_state_ref.val.virtual_effective_speed = if time_state_ref.val.virtual_paused {
        0.0F
      } else {
        time_state_ref.val.virtual_relative_speed
      }
      time_state_ref.val.virtual_was_paused = time_state_ref.val.virtual_paused
    }
    Some(last_update_seconds) => {
      let real_delta_seconds = if now > last_update_seconds {
        now - last_update_seconds
      } else {
        0.0F
      }
      let clamped_virtual_source_delta = if real_delta_seconds >
        time_state_ref.val.virtual_max_delta_seconds {
        time_state_ref.val.virtual_max_delta_seconds
      } else {
        real_delta_seconds
      }
      let effective_speed = if time_state_ref.val.virtual_paused {
        0.0F
      } else {
        time_state_ref.val.virtual_relative_speed
      }
      let virtual_delta_seconds = clamped_virtual_source_delta * effective_speed
      time_state_ref.val.real_delta_seconds = real_delta_seconds
      time_state_ref.val.real_elapsed_seconds = time_state_ref.val.real_elapsed_seconds +
        real_delta_seconds
      time_state_ref.val.virtual_delta_seconds = virtual_delta_seconds
      time_state_ref.val.virtual_elapsed_seconds = time_state_ref.val.virtual_elapsed_seconds +
        virtual_delta_seconds
      time_state_ref.val.virtual_effective_speed = effective_speed
      time_state_ref.val.virtual_was_paused = time_state_ref.val.virtual_paused
      time_state_ref.val.last_update_seconds = Some(now)
    }
  }
}

///|
pub fn[W] time_system(_world : W) -> Unit {
  time_update()
}

///|
fn time_update_resource_system(time : @app.ResMut[Time]) -> Unit {
  time_update()
  let change_tick = @app.current_system_ticks().this_run
  time.get_ref().val = time_snapshot()
  sync_resource(real_resource.val, real_snapshot(), change_tick)
  sync_resource(virtual_resource.val, virtual_snapshot(), change_tick)
  sync_resource(fixed_resource.val, fixed_snapshot(), change_tick)
}

///|
pub fn[W] time_plugin(app : @app.App[W]) -> @app.App[W] {
  @app.set_delta_seconds_provider(fn() { time_virtual_delta_seconds() })
  app
  .insert_resource(time_snapshot())
  .insert_resource(real_snapshot())
  .insert_resource(virtual_snapshot())
  .insert_resource(fixed_snapshot())
  .add_pre_update_system_param(time_update_resource_system)
}
