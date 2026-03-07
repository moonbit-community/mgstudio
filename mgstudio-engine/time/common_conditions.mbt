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
pub fn on_timer(duration : @core.Duration) -> @app.RunConditionFn[@ecs.World] {
  let timer_ref = Ref::new(Timer::new(duration, Repeating))
  fn(world : @ecs.World) -> Bool {
    timer_ref.val = timer_ref.val.tick(
      world_time_resource_or_default(world, default_time_resource_key(), fn() {
        let time : Time[Unit] = Time::default()
        time
      }).delta(),
    )
    timer_ref.val.just_finished()
  }
}

///|
pub fn on_real_timer(
  duration : @core.Duration,
) -> @app.RunConditionFn[@ecs.World] {
  let timer_ref = Ref::new(Timer::new(duration, Repeating))
  fn(world : @ecs.World) -> Bool {
    timer_ref.val = timer_ref.val.tick(world_real_or_default(world).delta())
    timer_ref.val.just_finished()
  }
}

///|
pub fn once_after_delay(
  duration : @core.Duration,
) -> @app.RunConditionFn[@ecs.World] {
  let timer_ref = Ref::new(Timer::new(duration, Once))
  fn(world : @ecs.World) -> Bool {
    timer_ref.val = timer_ref.val.tick(
      world_time_resource_or_default(world, default_time_resource_key(), fn() {
        let time : Time[Unit] = Time::default()
        time
      }).delta(),
    )
    timer_ref.val.just_finished()
  }
}

///|
pub fn once_after_real_delay(
  duration : @core.Duration,
) -> @app.RunConditionFn[@ecs.World] {
  let timer_ref = Ref::new(Timer::new(duration, Once))
  fn(world : @ecs.World) -> Bool {
    timer_ref.val = timer_ref.val.tick(world_real_or_default(world).delta())
    timer_ref.val.just_finished()
  }
}

///|
pub fn repeating_after_delay(
  duration : @core.Duration,
) -> @app.RunConditionFn[@ecs.World] {
  let timer_ref = Ref::new(Timer::new(duration, Once))
  fn(world : @ecs.World) -> Bool {
    timer_ref.val = timer_ref.val.tick(
      world_time_resource_or_default(world, default_time_resource_key(), fn() {
        let time : Time[Unit] = Time::default()
        time
      }).delta(),
    )
    timer_ref.val.is_finished()
  }
}

///|
pub fn repeating_after_real_delay(
  duration : @core.Duration,
) -> @app.RunConditionFn[@ecs.World] {
  let timer_ref = Ref::new(Timer::new(duration, Once))
  fn(world : @ecs.World) -> Bool {
    timer_ref.val = timer_ref.val.tick(world_real_or_default(world).delta())
    timer_ref.val.is_finished()
  }
}

///|
pub fn paused(world : @ecs.World) -> Bool {
  world_virtual_or_default(world).is_paused()
}
