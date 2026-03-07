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
let default_time_wrap_period : @core.Duration = @core.Duration::from_secs(3600L)

///|
pub struct Time[T] {
  context : T
  wrap_period : @core.Duration
  delta : @core.Duration
  delta_secs : Float
  delta_secs_f64 : Double
  elapsed : @core.Duration
  elapsed_secs : Float
  elapsed_secs_f64 : Double
  elapsed_wrapped : @core.Duration
  elapsed_secs_wrapped : Float
  elapsed_secs_wrapped_f64 : Double
}

///|
fn time_duration_rem(
  dividend : @core.Duration,
  divisor : @core.Duration,
) -> @core.Duration {
  if divisor.is_zero() {
    @core.Duration::zero()
  } else {
    let divisor_nanos = divisor.as_nanos()
    let positive_divisor_nanos = if divisor_nanos <= 0L {
      1L
    } else {
      divisor_nanos
    }
    let remainder_nanos = dividend.as_nanos() % positive_divisor_nanos
    @core.Duration::from_nanos(remainder_nanos)
  }
}

///|
fn[T] time_refresh_cached_seconds(time : Time[T]) -> Time[T] {
  {
    ..time,
    delta_secs: time.delta.as_secs_f32(),
    delta_secs_f64: time.delta.as_secs_f64(),
    elapsed_secs: time.elapsed.as_secs_f32(),
    elapsed_secs_f64: time.elapsed.as_secs_f64(),
    elapsed_secs_wrapped: time.elapsed_wrapped.as_secs_f32(),
    elapsed_secs_wrapped_f64: time.elapsed_wrapped.as_secs_f64(),
  }
}

///|
fn time_elapsed_wrapped_for(
  elapsed : @core.Duration,
  wrap_period : @core.Duration,
) -> @core.Duration {
  time_duration_rem(elapsed, wrap_period)
}

///|
fn time_time_or_default() -> Time[Unit] {
  world_time_resource_or_default(
    current_time_world_abort_missing(),
    default_time_resource_key(),
    fn() { Time::default() },
  )
}

///|
pub fn[T] Time::new_with(context : T) -> Time[T] {
  {
    context,
    wrap_period: default_time_wrap_period,
    delta: @core.Duration::zero(),
    delta_secs: 0.0F,
    delta_secs_f64: 0.0,
    elapsed: @core.Duration::zero(),
    elapsed_secs: 0.0F,
    elapsed_secs_f64: 0.0,
    elapsed_wrapped: @core.Duration::zero(),
    elapsed_secs_wrapped: 0.0F,
    elapsed_secs_wrapped_f64: 0.0,
  }
}

///|
pub impl[T : Default] Default for Time[T] with default() {
  Time::new_with(T::default())
}

///|
pub fn[T] Time::context(self : Time[T]) -> T {
  self.context
}

///|
pub fn[T] Time::wrap_period(self : Time[T]) -> @core.Duration {
  self.wrap_period
}

///|
pub fn[T] Time::wrap_period_seconds(self : Time[T]) -> Float {
  self.wrap_period.as_secs_f32()
}

///|
pub fn[T] Time::set_wrap_period(
  self : Time[T],
  wrap_period : @core.Duration,
) -> Time[T] {
  if wrap_period.is_zero() {
    abort("division by zero")
  }
  { ..self, wrap_period, }
}

///|
pub fn[T] Time::set_wrap_period_seconds(
  self : Time[T],
  wrap_period_seconds : Float,
) -> Time[T] {
  self.set_wrap_period(@core.Duration::from_secs_f32(wrap_period_seconds))
}

///|
pub fn[T] Time::advance_by(self : Time[T], delta : @core.Duration) -> Time[T] {
  let elapsed = self.elapsed.saturating_add(delta)
  {
    ..self,
    delta,
    elapsed,
    elapsed_wrapped: time_elapsed_wrapped_for(elapsed, self.wrap_period),
  }
  |> time_refresh_cached_seconds
}

///|
pub fn[T] Time::advance_to(self : Time[T], elapsed : @core.Duration) -> Time[T] {
  if elapsed.as_nanos() < self.elapsed.as_nanos() {
    abort("tried to move time backwards to an earlier elapsed moment")
  }
  self.advance_by(elapsed.saturating_sub(self.elapsed))
}

///|
pub fn[T] Time::delta(self : Time[T]) -> @core.Duration {
  self.delta
}

///|
pub fn[T] Time::delta_seconds(self : Time[T]) -> Float {
  self.delta_secs
}

///|
pub fn[T] Time::delta_secs(self : Time[T]) -> Float {
  self.delta_secs
}

///|
pub fn[T] Time::delta_secs_f64(self : Time[T]) -> Double {
  self.delta_secs_f64
}

///|
pub fn[T] Time::elapsed(self : Time[T]) -> @core.Duration {
  self.elapsed
}

///|
pub fn[T] Time::elapsed_seconds(self : Time[T]) -> Float {
  self.elapsed_secs
}

///|
pub fn[T] Time::elapsed_secs(self : Time[T]) -> Float {
  self.elapsed_secs
}

///|
pub fn[T] Time::elapsed_secs_f64(self : Time[T]) -> Double {
  self.elapsed_secs_f64
}

///|
pub fn[T] Time::elapsed_wrapped(self : Time[T]) -> @core.Duration {
  self.elapsed_wrapped
}

///|
pub fn[T] Time::elapsed_wrapped_seconds(self : Time[T]) -> Float {
  self.elapsed_secs_wrapped
}

///|
pub fn[T] Time::elapsed_secs_wrapped(self : Time[T]) -> Float {
  self.elapsed_secs_wrapped
}

///|
pub fn[T] Time::elapsed_secs_wrapped_f64(self : Time[T]) -> Double {
  self.elapsed_secs_wrapped_f64
}

///|
pub fn[T] Time::as_generic(self : Time[T]) -> Time[Unit] {
  {
    context: (),
    wrap_period: self.wrap_period,
    delta: self.delta,
    delta_secs: self.delta_secs,
    delta_secs_f64: self.delta_secs_f64,
    elapsed: self.elapsed,
    elapsed_secs: self.elapsed_secs,
    elapsed_secs_f64: self.elapsed_secs_f64,
    elapsed_wrapped: self.elapsed_wrapped,
    elapsed_secs_wrapped: self.elapsed_secs_wrapped,
    elapsed_secs_wrapped_f64: self.elapsed_secs_wrapped_f64,
  }
}

///|
pub fn time_delta() -> @core.Duration {
  time_time_or_default().delta()
}

///|
pub fn time_delta_seconds() -> Float {
  time_time_or_default().delta_seconds()
}

///|
pub fn time_elapsed() -> @core.Duration {
  time_time_or_default().elapsed()
}

///|
pub fn time_elapsed_seconds() -> Float {
  time_time_or_default().elapsed_seconds()
}
