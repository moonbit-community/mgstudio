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
fn time_sync_generic_time(change_tick : @core.Tick, value : Time) -> Unit {
  sync_resource(time_resource.val, value, change_tick)
}

///|
fn time_restore_virtual_as_generic(world : @ecs.World) -> Unit {
  let change_tick = world.increment_change_tick()
  let virtual_time = match virtual_resource.val.get() {
    Some(value) => value
    None => Virtual::new()
  }
  time_sync_generic_time(change_tick, virtual_time.as_generic())
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
    fixed_resource.val.insert(Fixed::new(), tick)
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
pub fn time_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  let startup_seconds = host_time_now()
  app
  .init_resource(fn() { Time::new() })
  .init_resource(fn() { Real::new(startup_seconds) })
  .init_resource(fn() { Virtual::new() })
  .init_resource(fn() { Fixed::new() })
  .init_resource(fn() { TimeUpdateStrategy::default() })
  .add_systems(
    @app.First,
    @app.system(@app.system_param4(time_update_resource_system)),
  )
  .add_systems(
    @app.RunFixedMainLoop,
    @app.system(time_run_fixed_main_schedule).in_set(
      @app.run_fixed_main_loop_system_set_name(
        @app.RunFixedMainLoopSystems::FixedMainLoop,
      ),
    ),
  )
}
