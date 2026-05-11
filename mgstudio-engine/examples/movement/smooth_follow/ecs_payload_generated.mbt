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
  EcsPayload_examples_movement_smooth_follow_TargetSphere(TargetSphere)
  EcsPayload_examples_movement_smooth_follow_FollowingSphere(FollowingSphere)
  EcsPayload_examples_movement_smooth_follow_TargetSphereSpeed(
    TargetSphereSpeed
  )
  EcsPayload_examples_movement_smooth_follow_TargetPosition(TargetPosition)
  EcsPayload_examples_movement_smooth_follow_DecayRate(DecayRate)
  EcsPayload_examples_movement_smooth_follow_RandomSource(RandomSource)
}

///|
impl @ecs.EcsPayloadCodec for TargetSphere with to_ecs_payload(self) {
  EcsPayload_examples_movement_smooth_follow_TargetSphere(self)
}

///|
impl @ecs.EcsPayloadCodec for TargetSphere with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_movement_smooth_follow_TargetSphere(value) =>
      Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for FollowingSphere with to_ecs_payload(self) {
  EcsPayload_examples_movement_smooth_follow_FollowingSphere(self)
}

///|
impl @ecs.EcsPayloadCodec for FollowingSphere with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_movement_smooth_follow_FollowingSphere(value) =>
      Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for TargetSphereSpeed with to_ecs_payload(self) {
  EcsPayload_examples_movement_smooth_follow_TargetSphereSpeed(self)
}

///|
impl @ecs.EcsPayloadCodec for TargetSphereSpeed with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_movement_smooth_follow_TargetSphereSpeed(value) =>
      Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for TargetPosition with to_ecs_payload(self) {
  EcsPayload_examples_movement_smooth_follow_TargetPosition(self)
}

///|
impl @ecs.EcsPayloadCodec for TargetPosition with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_movement_smooth_follow_TargetPosition(value) =>
      Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for DecayRate with to_ecs_payload(self) {
  EcsPayload_examples_movement_smooth_follow_DecayRate(self)
}

///|
impl @ecs.EcsPayloadCodec for DecayRate with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_movement_smooth_follow_DecayRate(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for RandomSource with to_ecs_payload(self) {
  EcsPayload_examples_movement_smooth_follow_RandomSource(self)
}

///|
impl @ecs.EcsPayloadCodec for RandomSource with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_movement_smooth_follow_RandomSource(value) =>
      Some(value)
    _ => None
  }
}
