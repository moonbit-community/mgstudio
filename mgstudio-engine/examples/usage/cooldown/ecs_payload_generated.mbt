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
  EcsPayload_examples_usage_cooldown_AbilityName(AbilityName)
  EcsPayload_examples_usage_cooldown_Cooldown(Cooldown)
  EcsPayload_examples_usage_cooldown_ActiveCooldown(ActiveCooldown)
  EcsPayload_examples_usage_cooldown_StatusLabel(StatusLabel)
}

///|
impl @ecs.EcsPayloadCodec for AbilityName with to_ecs_payload(self) {
  EcsPayload_examples_usage_cooldown_AbilityName(self)
}

///|
impl @ecs.EcsPayloadCodec for AbilityName with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_usage_cooldown_AbilityName(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for Cooldown with to_ecs_payload(self) {
  EcsPayload_examples_usage_cooldown_Cooldown(self)
}

///|
impl @ecs.EcsPayloadCodec for Cooldown with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_usage_cooldown_Cooldown(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for ActiveCooldown with to_ecs_payload(self) {
  EcsPayload_examples_usage_cooldown_ActiveCooldown(self)
}

///|
impl @ecs.EcsPayloadCodec for ActiveCooldown with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_usage_cooldown_ActiveCooldown(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for StatusLabel with to_ecs_payload(self) {
  EcsPayload_examples_usage_cooldown_StatusLabel(self)
}

///|
impl @ecs.EcsPayloadCodec for StatusLabel with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_usage_cooldown_StatusLabel(value) => Some(value)
    _ => None
  }
}
