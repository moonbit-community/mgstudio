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
pub impl @app.Plugin for TimePlugin with name(_self) {
  "mgstudio.time.TimePlugin"
}

///|
pub impl @app.Plugin for TimePlugin with build(_self, app) {
  time_plugin(app)
}

///|
pub(all) enum TimeUpdateStrategy {
  Automatic
  ManualInstant(@core.Instant)
  ManualDuration(@core.Duration)
  FixedTimesteps(Int)
} derive(Eq, Debug)

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
        "mgstudio_time helper functions require an active app world; use direct world resource access outside scheduled systems",
      )
  }
}

///|
let time_resource_registry : Ref[@hashmap.HashMap[String, @any.Any]] = Ref::new(
  @hashmap.HashMap::new(),
)

///|
let time_update_strategy_resource_key : @ecs.ResourceKey[TimeUpdateStrategy] = @ecs.register_resource(
  debug_name="mgstudio_time::TimeUpdateStrategy",
)

///|
fn[T : Default] registered_time_resource_key() -> @ecs.ResourceKey[Time[T]] {
  let probe : Time[T] = Time::default()
  let type_name = @any.of(probe).type_name()
  match time_resource_registry.val.get(type_name) {
    Some(existing_key) =>
      match existing_key.try_to() {
        Some(key) => key
        None =>
          abort(
            "time resource registry contained a mismatched key for \{type_name}",
          )
      }
    None => {
      let key : @ecs.ResourceKey[Time[T]] = @ecs.register_resource(
        debug_name="mgstudio_time::\{type_name}",
      )
      time_resource_registry.val.set(type_name, @any.of(key))
      key
    }
  }
}

///|
pub fn default_time_resource_key() -> @ecs.ResourceKey[Time[Unit]] {
  registered_time_resource_key()
}

///|
pub fn real_time_resource_key() -> @ecs.ResourceKey[Time[Real]] {
  registered_time_resource_key()
}

///|
pub fn virtual_time_resource_key() -> @ecs.ResourceKey[Time[Virtual]] {
  registered_time_resource_key()
}

///|
pub fn fixed_time_resource_key() -> @ecs.ResourceKey[Time[Fixed]] {
  registered_time_resource_key()
}

///|
pub impl[T : Default] @app.Resource for Time[T] with resource() {
  registered_time_resource_key()
}

///|
pub impl @app.Resource for TimeUpdateStrategy with resource() {
  time_update_strategy_resource_key
}

///|
pub fn host_time_now() -> Float {
  @core.Instant::now().as_secs_f32()
}

///|
pub fn host_time_now_instant() -> @core.Instant {
  @core.Instant::now()
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
) -> Unit {
  match
    (try world.get_resource_mut(key) catch {
      _ => None
    } noraise {
      value => value
    }) {
    Some(cell) => cell.set(value)
    None => world.insert_resource(key, value)
  }
}

///|
fn time_sync_generic_time(world : @ecs.World, value : Time[Unit]) -> Unit {
  sync_world_time_resource(world, default_time_resource_key(), value)
}

///|
fn time_restore_virtual_as_generic(world : @ecs.World) -> Unit {
  let virtual_time = world_time_resource_or_default(
    world,
    virtual_time_resource_key(),
    fn() {
      let time : Time[Virtual] = Time::default()
      time
    },
  )
  time_sync_generic_time(world, virtual_time.as_generic())
}

///|
fn ensure_time_resources(world : @ecs.World) -> Unit {
  if world_time_resource(world, default_time_resource_key()) is None {
    let time : Time[Unit] = Time::default()
    world.insert_resource(default_time_resource_key(), time)
  }
  if world_time_resource(world, real_time_resource_key()) is None {
    world.insert_resource(
      real_time_resource_key(),
      Time::new(host_time_now_instant()),
    )
  }
  if world_time_resource(world, virtual_time_resource_key()) is None {
    let time : Time[Virtual] = Time::default()
    world.insert_resource(virtual_time_resource_key(), time)
  }
  if world_time_resource(world, fixed_time_resource_key()) is None {
    let time : Time[Fixed] = Time::default()
    world.insert_resource(fixed_time_resource_key(), time)
  }
  if world_time_resource(world, time_update_strategy_resource_key) is None {
    world.insert_resource(
      time_update_strategy_resource_key,
      TimeUpdateStrategy::default(),
    )
  }
}

///|
fn time_update_real_with_strategy(
  real_time : Time[Real],
  strategy : TimeUpdateStrategy,
  fixed_time : Time[Fixed],
) -> Time[Real] {
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
  let strategy = world_time_resource_or_default(
    world,
    time_update_strategy_resource_key,
    TimeUpdateStrategy::default,
  )
  let fixed_time = world_fixed_or_default(world)
  let real_ref = try! world.get_resource_mut(real_time_resource_key()).unwrap()
  let virtual_ref = try! world
    .get_resource_mut(virtual_time_resource_key())
    .unwrap()
  let time_ref = try! world
    .get_resource_mut(default_time_resource_key())
    .unwrap()
  let next_real = time_update_real_with_strategy(
    real_ref.peek(),
    strategy,
    fixed_time,
  )
  let next_virtual = update_virtual_time(virtual_ref.peek(), next_real)
  real_ref.set(next_real)
  virtual_ref.set(next_virtual)
  time_ref.set(next_virtual.as_generic())
}

///|
fn time_update_resource_system(world : @ecs.World) -> Unit {
  time_update(world)
}

///|
pub fn time_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  let startup_instant = host_time_now_instant()
  app
  .init_resource(fn() {
    let time : Time[Unit] = Time::default()
    time
  })
  .init_resource(fn() { Time::new(startup_instant) })
  .init_resource(fn() {
    let time : Time[Virtual] = Time::default()
    time
  })
  .init_resource(fn() {
    let time : Time[Fixed] = Time::default()
    time
  })
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
