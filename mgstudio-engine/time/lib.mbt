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
  ManualInstant(@core.Instant)
  ManualDuration(@core.Duration)
  FixedTimesteps(Int)
} derive(Eq, Show)

///|
pub fn TimeUpdateStrategy::default() -> TimeUpdateStrategy {
  Automatic
}

///|
fn current_time_world_abort_missing() -> @ecs.World {
  match @app.current_world() {
    Some(world) => world
    None =>
      abort(
        "bevy_time helper functions require an active app world; use direct world resource access outside scheduled systems",
      )
  }
}

///|
let time_resource_key : @ecs.ResourceKey[Time] = @ecs.register_resource(
  debug_name="bevy_time::Time",
)

///|
let real_resource_key : @ecs.ResourceKey[Real] = @ecs.register_resource(
  debug_name="bevy_time::Real",
)

///|
let virtual_resource_key : @ecs.ResourceKey[Virtual] = @ecs.register_resource(
  debug_name="bevy_time::Virtual",
)

///|
let fixed_resource_key : @ecs.ResourceKey[Fixed] = @ecs.register_resource(
  debug_name="bevy_time::Fixed",
)

///|
let time_update_strategy_resource_key : @ecs.ResourceKey[TimeUpdateStrategy] = @ecs.register_resource(
  debug_name="bevy_time::TimeUpdateStrategy",
)

///|
pub impl @app.Resource for Time with resource() {
  time_resource_key
}

///|
pub impl @app.Resource for Real with resource() {
  real_resource_key
}

///|
pub impl @app.Resource for Virtual with resource() {
  virtual_resource_key
}

///|
pub impl @app.Resource for Fixed with resource() {
  fixed_resource_key
}

///|
pub impl @app.Resource for TimeUpdateStrategy with resource() {
  time_update_strategy_resource_key
}

///|
pub fn host_time_now() -> Float {
  @native_time.now()
}

///|
pub fn host_time_now_instant() -> @core.Instant {
  @core.Instant::now()
}

///|
fn time_resource_change_tick(world : @ecs.World) -> @core.Tick {
  let tick = @app.current_system_ticks().this_run
  if tick > 0 {
    tick
  } else {
    let world_tick = world.read_change_tick()
    if world_tick > 0 {
      world_tick
    } else {
      1
    }
  }
}

///|
fn[T] world_time_resource(world : @ecs.World, key : @ecs.ResourceKey[T]) -> T? {
  try world.get_resource(key) catch {
    _ => None
  } noraise {
    value => value
  }
}

///|
fn[T] world_time_resource_or_default(
  world : @ecs.World,
  key : @ecs.ResourceKey[T],
  default_value : () -> T,
) -> T {
  match world_time_resource(world, key) {
    Some(value) => value
    None => default_value()
  }
}

///|
fn[T] sync_world_time_resource(
  world : @ecs.World,
  key : @ecs.ResourceKey[T],
  value : T,
  change_tick : @core.Tick,
) -> Unit {
  match
    (try world.get_resource_ref_mut(key, change_tick) catch {
      _ => None
    } noraise {
      value => value
    }) {
    Some(cell) => cell.val = value
    None => world.insert_resource_with_change_tick(key, value, change_tick)
  }
}

///|
fn time_sync_generic_time(
  world : @ecs.World,
  change_tick : @core.Tick,
  value : Time,
) -> Unit {
  sync_world_time_resource(world, time_resource_key, value, change_tick)
}

///|
fn time_restore_virtual_as_generic(world : @ecs.World) -> Unit {
  let change_tick = world.increment_change_tick()
  let virtual_time = world_time_resource_or_default(
    world,
    virtual_resource_key,
    Virtual::new,
  )
  time_sync_generic_time(world, change_tick, virtual_time.as_generic())
}

///|
fn ensure_time_resources(world : @ecs.World) -> Unit {
  let tick = time_resource_change_tick(world)
  if world_time_resource(world, time_resource_key) is None {
    world.insert_resource_with_change_tick(time_resource_key, Time::new(), tick)
  }
  if world_time_resource(world, real_resource_key) is None {
    world.insert_resource_with_change_tick(
      real_resource_key,
      Real::new(host_time_now_instant()),
      tick,
    )
  }
  if world_time_resource(world, virtual_resource_key) is None {
    world.insert_resource_with_change_tick(
      virtual_resource_key,
      Virtual::new(),
      tick,
    )
  }
  if world_time_resource(world, fixed_resource_key) is None {
    world.insert_resource_with_change_tick(
      fixed_resource_key,
      Fixed::new(),
      tick,
    )
  }
  if world_time_resource(world, time_update_strategy_resource_key) is None {
    world.insert_resource_with_change_tick(
      time_update_strategy_resource_key,
      TimeUpdateStrategy::default(),
      tick,
    )
  }
}

///|
fn time_update_real_with_strategy(
  real_time : Real,
  strategy : TimeUpdateStrategy,
  fixed_time : Fixed,
) -> Real {
  match strategy {
    Automatic => real_time.update()
    ManualInstant(now_instant) => real_time.update_with_instant(now_instant)
    ManualDuration(duration) => real_time.update_with_duration(duration)
    FixedTimesteps(factor) => {
      let steps = if factor < 0 { 0 } else { factor }
      real_time.update_with_duration(fixed_time.timestep().mul_int(steps))
    }
  }
}

///|
fn time_update(world : @ecs.World) -> Unit {
  ensure_time_resources(world)
  let tick = time_resource_change_tick(world)
  let strategy = world_time_resource_or_default(
    world,
    time_update_strategy_resource_key,
    TimeUpdateStrategy::default,
  )
  let fixed_time = world_fixed_or_default(world)
  let real_ref = try! world
    .get_resource_ref_mut(real_resource_key, tick)
    .unwrap()
  let virtual_ref = try! world
    .get_resource_ref_mut(virtual_resource_key, tick)
    .unwrap()
  let time_ref = try! world
    .get_resource_ref_mut(time_resource_key, tick)
    .unwrap()
  let next_real = time_update_real_with_strategy(
    real_ref.val,
    strategy,
    fixed_time,
  )
  let next_virtual = update_virtual_time(virtual_ref.val, next_real)
  real_ref.val = next_real
  virtual_ref.val = next_virtual
  time_ref.val = next_virtual.as_generic()
}

///|
fn time_update_resource_system(world : @ecs.World) -> Unit {
  time_update(world)
}

///|
pub fn time_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  let startup_instant = host_time_now_instant()
  app
  .init_resource(fn() { Time::new() })
  .init_resource(fn() { Real::new(startup_instant) })
  .init_resource(fn() { Virtual::new() })
  .init_resource(fn() { Fixed::new() })
  .init_resource(fn() { TimeUpdateStrategy::default() })
  .add_systems(@app.First, @app.system(time_update_resource_system))
  .add_systems(
    @app.RunFixedMainLoop,
    @app.system(time_run_fixed_main_schedule).in_set(
      @app.run_fixed_main_loop_system_set_name(
        @app.RunFixedMainLoopSystems::FixedMainLoop,
      ),
    ),
  )
}
