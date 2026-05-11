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
  EcsPayload_examples_ecs_one_shot_systems_Callback(Callback)
  EcsPayload_examples_ecs_one_shot_systems_Triggered(Triggered)
  EcsPayload_examples_ecs_one_shot_systems_CallbackA(CallbackA)
  EcsPayload_examples_ecs_one_shot_systems_CallbackB(CallbackB)
  EcsPayload_examples_ecs_one_shot_systems_LastTriggeredLabel(
    LastTriggeredLabel
  )
}

///|
impl @ecs.EcsPayloadCodec for Callback with to_ecs_payload(self) {
  EcsPayload_examples_ecs_one_shot_systems_Callback(self)
}

///|
impl @ecs.EcsPayloadCodec for Callback with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_ecs_one_shot_systems_Callback(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for Triggered with to_ecs_payload(self) {
  EcsPayload_examples_ecs_one_shot_systems_Triggered(self)
}

///|
impl @ecs.EcsPayloadCodec for Triggered with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_ecs_one_shot_systems_Triggered(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for CallbackA with to_ecs_payload(self) {
  EcsPayload_examples_ecs_one_shot_systems_CallbackA(self)
}

///|
impl @ecs.EcsPayloadCodec for CallbackA with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_ecs_one_shot_systems_CallbackA(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for CallbackB with to_ecs_payload(self) {
  EcsPayload_examples_ecs_one_shot_systems_CallbackB(self)
}

///|
impl @ecs.EcsPayloadCodec for CallbackB with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_ecs_one_shot_systems_CallbackB(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for LastTriggeredLabel with to_ecs_payload(self) {
  EcsPayload_examples_ecs_one_shot_systems_LastTriggeredLabel(self)
}

///|
impl @ecs.EcsPayloadCodec for LastTriggeredLabel with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_ecs_one_shot_systems_LastTriggeredLabel(value) =>
      Some(value)
    _ => None
  }
}
