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
let active_time_world_ref : Ref[@ecs.World?] = Ref::new(None)

///|
let fallback_time_world_ref : Ref[@ecs.World] = Ref::new(@ecs.World::new())

///|
fn time_resource_world() -> @ecs.World {
  match @app.current_world() {
    Some(world) => {
      active_time_world_ref.val = Some(world)
      world
    }
    None =>
      match active_time_world_ref.val {
        Some(world) => world
        None => fallback_time_world_ref.val
      }
  }
}

///|
priv struct WorldOwnedResourceProxy[T] {
  key : @ecs.ResourceKey[T]
}

///|
fn[T] WorldOwnedResourceProxy::new(
  key : @ecs.ResourceKey[T],
) -> WorldOwnedResourceProxy[T] {
  WorldOwnedResourceProxy::{ key, }
}

///|
fn[T] WorldOwnedResourceProxy::is_present(
  self : WorldOwnedResourceProxy[T],
) -> Bool {
  match
    (try time_resource_world().get_resource(self.key) catch {
      _ => None
    } noraise {
      value => value
    }) {
    Some(_) => true
    None => false
  }
}

///|
fn[T] WorldOwnedResourceProxy::insert(
  self : WorldOwnedResourceProxy[T],
  value : T,
  change_tick : @core.Tick,
) -> Unit {
  time_resource_world().insert_resource_with_change_tick(
    self.key,
    value,
    change_tick,
  )
}

///|
fn[T] WorldOwnedResourceProxy::get(self : WorldOwnedResourceProxy[T]) -> T? {
  try time_resource_world().get_resource(self.key) catch {
    _ => None
  } noraise {
    value => value
  }
}

///|
fn[T] WorldOwnedResourceProxy::get_ref_mut(
  self : WorldOwnedResourceProxy[T],
  change_tick : @core.Tick,
) -> Ref[T]? {
  try time_resource_world().get_resource_ref_mut(self.key, change_tick) catch {
    _ => None
  } noraise {
    value => value
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
let time_resource : Ref[WorldOwnedResourceProxy[Time]] = Ref::new(
  WorldOwnedResourceProxy::new(time_resource_key),
)

///|
let real_resource : Ref[WorldOwnedResourceProxy[Real]] = Ref::new(
  WorldOwnedResourceProxy::new(real_resource_key),
)

///|
let virtual_resource : Ref[WorldOwnedResourceProxy[Virtual]] = Ref::new(
  WorldOwnedResourceProxy::new(virtual_resource_key),
)

///|
let fixed_resource : Ref[WorldOwnedResourceProxy[Fixed]] = Ref::new(
  WorldOwnedResourceProxy::new(fixed_resource_key),
)

///|
let time_update_strategy_resource : Ref[
  WorldOwnedResourceProxy[TimeUpdateStrategy],
] = Ref::new(WorldOwnedResourceProxy::new(time_update_strategy_resource_key))

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
fn time_resource_change_tick() -> @core.Tick {
  let tick = @app.current_system_ticks().this_run
  if tick > 0 {
    tick
  } else {
    let world_tick = time_resource_world().read_change_tick()
    if world_tick > 0 {
      world_tick
    } else {
      1
    }
  }
}

///|
fn[T] sync_resource(
  resource : WorldOwnedResourceProxy[T],
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
  active_time_world_ref.val = Some(app.world())
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
