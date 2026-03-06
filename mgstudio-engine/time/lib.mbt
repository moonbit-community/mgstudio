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
fn time_resource_change_tick() -> @core.Tick {
  let tick = @app.current_system_ticks().this_run
  if tick > 0 {
    tick
  } else {
    1
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
fn ensure_time_resources() -> Unit {
  let tick = time_resource_change_tick()
  if !time_resource.val.is_present() {
    time_resource.val.insert(Time::new(), tick)
  }
  if !real_resource.val.is_present() {
    real_resource.val.insert(Real::new(host_time_now()), tick)
  }
  if !virtual_resource.val.is_present() {
    virtual_resource.val.insert(Virtual::new(), tick)
  }
  if !fixed_resource.val.is_present() {
    fixed_resource.val.insert(Fixed::new().sync_from_app_state(), tick)
  }
  if !time_update_strategy_resource.val.is_present() {
    time_update_strategy_resource.val.insert(
      TimeUpdateStrategy::default(),
      tick,
    )
  }
}

///|
fn time_update_real_with_strategy(
  real_time : Real,
  strategy : TimeUpdateStrategy,
) -> Real {
  match strategy {
    Automatic => real_time.update()
    ManualInstant(now_seconds) => real_time.update_with_instant(now_seconds)
    ManualDuration(duration_seconds) =>
      real_time.update_with_duration(duration_seconds)
    FixedTimesteps(factor) => {
      let steps = if factor < 0 { 0 } else { factor }
      real_time.update_with_duration(
        time_fixed_timestep_seconds() * Float::from_int(steps),
      )
    }
  }
}

///|
pub fn time_update() -> Unit {
  ensure_time_resources()
  let tick = time_resource_change_tick()
  let strategy = match time_update_strategy_resource.val.get() {
    Some(strategy) => strategy
    None => TimeUpdateStrategy::default()
  }
  let real_ref = real_resource.val.get_ref_mut(tick).unwrap()
  let virtual_ref = virtual_resource.val.get_ref_mut(tick).unwrap()
  let time_ref = time_resource.val.get_ref_mut(tick).unwrap()
  let next_real = time_update_real_with_strategy(real_ref.val, strategy)
  let next_virtual = update_virtual_time(virtual_ref.val, next_real)
  real_ref.val = next_real
  virtual_ref.val = next_virtual
  time_ref.val = next_virtual.as_generic()
}

///|
pub fn[W] time_system(_world : W) -> Unit {
  time_update()
}

///|
fn time_update_resource_system(
  time : @app.ResMut[Time],
  real_time : @app.ResMut[Real],
  virtual_time : @app.ResMut[Virtual],
  strategy : @app.Res[TimeUpdateStrategy],
) -> Unit {
  let next_real = time_update_real_with_strategy(
    real_time.get_ref().val,
    strategy.get(),
  )
  let next_virtual = update_virtual_time(virtual_time.get_ref().val, next_real)
  real_time.get_ref().val = next_real
  virtual_time.get_ref().val = next_virtual
  time.get_ref().val = next_virtual.as_generic()
}

///|
fn time_sync_fixed_resource_system(fixed_time : @app.ResMut[Fixed]) -> Unit {
  fixed_time.get_ref().val = fixed_time.get_ref().val.sync_from_app_state()
}

///|
pub fn[W] time_plugin(app : @app.App[W]) -> @app.App[W] {
  let startup_seconds = host_time_now()
  @app.fixed_time_reset()
  @app.set_delta_seconds_provider(fn() { time_virtual_delta_seconds() })
  app
  .insert_resource(Time::new())
  .insert_resource(Real::new(startup_seconds))
  .insert_resource(Virtual::new())
  .insert_resource(Fixed::new().sync_from_app_state())
  .insert_resource(TimeUpdateStrategy::default())
  .add_fixed_update_system_param(time_sync_fixed_resource_system)
  .add_pre_update_system_param4(time_update_resource_system)
}
