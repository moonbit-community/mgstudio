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
pub(all) enum TimeUpdateStrategy {
  Automatic
  ManualInstant(Float)
  ManualDuration(Float)
  FixedTimesteps(Int)
} derive(Eq, Show)

///|
pub fn TimeUpdateStrategy::default() -> TimeUpdateStrategy {
  Automatic
}

///|
priv struct TimeState {
  mut startup_seconds : Float
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
let time_update_strategy_resource : Ref[@core.Resource[TimeUpdateStrategy]] = Ref::new(
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
pub impl @app.Resource for TimeUpdateStrategy with resource() {
  time_update_strategy_resource.val
}

///|
pub fn host_time_now() -> Float {
  @native_time.now()
}

///|
fn time_reset_state(startup_seconds : Float) -> Unit {
  time_state_ref.val.startup_seconds = startup_seconds
  time_state_ref.val.first_update_seconds = None
  time_state_ref.val.last_update_seconds = None
  time_state_ref.val.real_delta_seconds = 0.0F
  time_state_ref.val.real_elapsed_seconds = 0.0F
  time_state_ref.val.virtual_delta_seconds = 0.0F
  time_state_ref.val.virtual_elapsed_seconds = 0.0F
  time_state_ref.val.virtual_relative_speed = 1.0F
  time_state_ref.val.virtual_effective_speed = 1.0F
  time_state_ref.val.virtual_max_delta_seconds = DEFAULT_VIRTUAL_MAX_DELTA_SECONDS
  time_state_ref.val.virtual_paused = false
  time_state_ref.val.virtual_was_paused = false
}

///|
fn time_reset() -> Unit {
  time_reset_state(host_time_now())
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
fn time_update_real_with_instant(now : Float) -> Unit {
  match time_state_ref.val.last_update_seconds {
    None => {
      time_state_ref.val.first_update_seconds = Some(now)
      time_state_ref.val.last_update_seconds = Some(now)
      time_state_ref.val.real_delta_seconds = 0.0F
    }
    Some(last_update_seconds) => {
      let real_delta_seconds = if now > last_update_seconds {
        now - last_update_seconds
      } else {
        0.0F
      }
      time_state_ref.val.real_delta_seconds = real_delta_seconds
      time_state_ref.val.real_elapsed_seconds = time_state_ref.val.real_elapsed_seconds +
        real_delta_seconds
      time_state_ref.val.last_update_seconds = Some(now)
    }
  }
}

///|
fn time_update_real_with_duration(duration_seconds : Float) -> Unit {
  let delta_seconds = if duration_seconds < 0.0F {
    0.0F
  } else {
    duration_seconds
  }
  let last_update_seconds = match time_state_ref.val.last_update_seconds {
    Some(last) => last
    None => time_state_ref.val.startup_seconds
  }
  time_update_real_with_instant(last_update_seconds + delta_seconds)
}

///|
fn time_update_virtual_from_real_delta() -> Unit {
  let raw_delta_seconds = time_state_ref.val.real_delta_seconds
  let clamped_virtual_source_delta = if raw_delta_seconds >
    time_state_ref.val.virtual_max_delta_seconds {
    time_state_ref.val.virtual_max_delta_seconds
  } else {
    raw_delta_seconds
  }
  let effective_speed = if time_state_ref.val.virtual_paused {
    0.0F
  } else {
    time_state_ref.val.virtual_relative_speed
  }
  let virtual_delta_seconds = clamped_virtual_source_delta * effective_speed
  time_state_ref.val.virtual_delta_seconds = virtual_delta_seconds
  time_state_ref.val.virtual_elapsed_seconds = time_state_ref.val.virtual_elapsed_seconds +
    virtual_delta_seconds
  time_state_ref.val.virtual_effective_speed = effective_speed
  time_state_ref.val.virtual_was_paused = time_state_ref.val.virtual_paused
}

///|
fn time_update_with_strategy(strategy : TimeUpdateStrategy) -> Unit {
  match strategy {
    Automatic => time_update_real_with_instant(host_time_now())
    ManualInstant(now) => time_update_real_with_instant(now)
    ManualDuration(duration_seconds) =>
      time_update_real_with_duration(duration_seconds)
    FixedTimesteps(factor) => {
      let steps = if factor < 0 { 0 } else { factor }
      let timestep_seconds = time_fixed_timestep_seconds()
      time_update_real_with_duration(timestep_seconds * Float::from_int(steps))
    }
  }
  time_update_virtual_from_real_delta()
}

///|
pub fn time_update() -> Unit {
  let strategy = match time_update_strategy_resource.val.get() {
    Some(value) => value
    None => TimeUpdateStrategy::default()
  }
  time_update_with_strategy(strategy)
}

///|
pub fn[W] time_system(_world : W) -> Unit {
  time_update()
}

///|
fn time_update_resource_system(
  time : @app.ResMut[Time],
  strategy : @app.Res[TimeUpdateStrategy],
) -> Unit {
  time_update_with_strategy(strategy.get())
  let change_tick = @app.current_system_ticks().this_run
  time.get_ref().val = time_snapshot()
  sync_resource(real_resource.val, real_snapshot(), change_tick)
  sync_resource(virtual_resource.val, virtual_snapshot(), change_tick)
  sync_resource(fixed_resource.val, fixed_snapshot(), change_tick)
}

///|
fn time_sync_fixed_resource_system(fixed : @app.ResMut[Fixed]) -> Unit {
  fixed.get_ref().val = fixed_snapshot()
}

///|
pub fn[W] time_plugin(app : @app.App[W]) -> @app.App[W] {
  time_reset()
  @app.fixed_time_reset()
  @app.set_delta_seconds_provider(fn() { time_virtual_delta_seconds() })
  app
  .insert_resource(time_snapshot())
  .insert_resource(real_snapshot())
  .insert_resource(virtual_snapshot())
  .insert_resource(fixed_snapshot())
  .insert_resource(TimeUpdateStrategy::default())
  .add_fixed_update_system_param(time_sync_fixed_resource_system)
  .add_pre_update_system_param2(time_update_resource_system)
}
