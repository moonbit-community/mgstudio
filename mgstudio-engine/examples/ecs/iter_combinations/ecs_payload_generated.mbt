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
  EcsPayload_examples_ecs_iter_combinations_Mass(Mass)
  EcsPayload_examples_ecs_iter_combinations_Velocity(Velocity)
  EcsPayload_examples_ecs_iter_combinations_Acceleration(Acceleration)
  EcsPayload_examples_ecs_iter_combinations_Star(Star)
}

///|
impl @ecs.EcsPayloadCodec for Mass with to_ecs_payload(self) {
  EcsPayload_examples_ecs_iter_combinations_Mass(self)
}

///|
impl @ecs.EcsPayloadCodec for Mass with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_ecs_iter_combinations_Mass(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for Velocity with to_ecs_payload(self) {
  EcsPayload_examples_ecs_iter_combinations_Velocity(self)
}

///|
impl @ecs.EcsPayloadCodec for Velocity with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_ecs_iter_combinations_Velocity(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for Acceleration with to_ecs_payload(self) {
  EcsPayload_examples_ecs_iter_combinations_Acceleration(self)
}

///|
impl @ecs.EcsPayloadCodec for Acceleration with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_ecs_iter_combinations_Acceleration(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for Star with to_ecs_payload(self) {
  EcsPayload_examples_ecs_iter_combinations_Star(self)
}

///|
impl @ecs.EcsPayloadCodec for Star with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_ecs_iter_combinations_Star(value) => Some(value)
    _ => None
  }
}
