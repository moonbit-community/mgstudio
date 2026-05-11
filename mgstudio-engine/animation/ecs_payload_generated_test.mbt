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
  EcsPayload_animation_TestTypedAnimationEvent(TestTypedAnimationEvent)
  EcsPayload_animation_ObservedTypedAnimationEvent(ObservedTypedAnimationEvent)
}

///|
pub impl @ecs.EcsPayloadCodec for TestTypedAnimationEvent with to_ecs_payload(
  self,
) {
  EcsPayload_animation_TestTypedAnimationEvent(self)
}

///|
pub impl @ecs.EcsPayloadCodec for TestTypedAnimationEvent with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_animation_TestTypedAnimationEvent(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ObservedTypedAnimationEvent with to_ecs_payload(
  self,
) {
  EcsPayload_animation_ObservedTypedAnimationEvent(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ObservedTypedAnimationEvent with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_animation_ObservedTypedAnimationEvent(value) => Some(value)
    _ => None
  }
}
