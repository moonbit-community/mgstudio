// Copyright 2026 International Digital Economy Academy
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

///|
extenum @ecs.EcsPayload += {
  EcsPayload_time_TimeUpdateStrategy(TimeUpdateStrategy)
  EcsPayload_time_Real(Real)
  EcsPayload_time_Virtual(Virtual)
  EcsPayload_time_Fixed(Fixed)
  EcsPayload_time_Time(TimePayload)
}

///|
pub impl @ecs.EcsPayloadCodec for TimeUpdateStrategy with to_ecs_payload(self) {
  EcsPayload_time_TimeUpdateStrategy(self)
}

///|
pub impl @ecs.EcsPayloadCodec for TimeUpdateStrategy with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_time_TimeUpdateStrategy(value) => Some(value)
    _ => None
  }
}

///|
pub(all) struct TimePayload {
  context : @ecs.EcsPayload
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
pub impl @ecs.EcsPayloadCodec for Real with to_ecs_payload(self) {
  EcsPayload_time_Real(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Real with from_ecs_payload(payload) {
  match payload {
    EcsPayload_time_Real(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Virtual with to_ecs_payload(self) {
  EcsPayload_time_Virtual(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Virtual with from_ecs_payload(payload) {
  match payload {
    EcsPayload_time_Virtual(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Fixed with to_ecs_payload(self) {
  EcsPayload_time_Fixed(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Fixed with from_ecs_payload(payload) {
  match payload {
    EcsPayload_time_Fixed(value) => Some(value)
    _ => None
  }
}

///|
pub impl[T : @ecs.EcsPayloadCodec] @ecs.EcsPayloadCodec for Time[T] with to_ecs_payload(
  self,
) {
  EcsPayload_time_Time(TimePayload::{
    context: T::to_ecs_payload(self.context),
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
  })
}

///|
pub impl[T : @ecs.EcsPayloadCodec] @ecs.EcsPayloadCodec for Time[T] with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_time_Time(value) =>
      match T::from_ecs_payload(value.context) {
        Some(context) =>
          Some(Time::{
            context,
            wrap_period: value.wrap_period,
            delta: value.delta,
            delta_secs: value.delta_secs,
            delta_secs_f64: value.delta_secs_f64,
            elapsed: value.elapsed,
            elapsed_secs: value.elapsed_secs,
            elapsed_secs_f64: value.elapsed_secs_f64,
            elapsed_wrapped: value.elapsed_wrapped,
            elapsed_secs_wrapped: value.elapsed_secs_wrapped,
            elapsed_secs_wrapped_f64: value.elapsed_secs_wrapped_f64,
          })
        None => None
      }
    _ => None
  }
}
