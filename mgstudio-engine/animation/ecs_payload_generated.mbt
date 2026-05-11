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
  EcsPayload_animation_AnimationTriggeredEvent(AnimationTriggeredEvent)
  EcsPayload_animation_AnimationTargetId(AnimationTargetId)
  EcsPayload_animation_AnimatedBy(AnimatedBy)
  EcsPayload_animation_AnimationPlayer(AnimationPlayer)
  EcsPayload_animation_AnimationClip(AnimationClip)
  EcsPayload_animation_AnimationGraph(AnimationGraph)
  EcsPayload_animation_AnimationGraphHandle(AnimationGraphHandle)
  EcsPayload_animation_AnimationTransitions(AnimationTransitions)
  EcsPayload_animation_AnimationWeights(AnimationWeights)
  EcsPayload_animation_ThreadedAnimationGraphs(ThreadedAnimationGraphs)
  EcsPayload_animation_AnimationRuntimeScratch(AnimationRuntimeScratch)
}

///|
pub impl @ecs.EcsPayloadCodec for AnimationTriggeredEvent with to_ecs_payload(
  self,
) {
  EcsPayload_animation_AnimationTriggeredEvent(self)
}

///|
pub impl @ecs.EcsPayloadCodec for AnimationTriggeredEvent with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_animation_AnimationTriggeredEvent(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for AnimationTargetId with to_ecs_payload(self) {
  EcsPayload_animation_AnimationTargetId(self)
}

///|
pub impl @ecs.EcsPayloadCodec for AnimationTargetId with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_animation_AnimationTargetId(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for AnimatedBy with to_ecs_payload(self) {
  EcsPayload_animation_AnimatedBy(self)
}

///|
pub impl @ecs.EcsPayloadCodec for AnimatedBy with from_ecs_payload(payload) {
  match payload {
    EcsPayload_animation_AnimatedBy(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for AnimationPlayer with to_ecs_payload(self) {
  EcsPayload_animation_AnimationPlayer(self)
}

///|
pub impl @ecs.EcsPayloadCodec for AnimationPlayer with from_ecs_payload(payload) {
  match payload {
    EcsPayload_animation_AnimationPlayer(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for AnimationClip with to_ecs_payload(self) {
  EcsPayload_animation_AnimationClip(self)
}

///|
pub impl @ecs.EcsPayloadCodec for AnimationClip with from_ecs_payload(payload) {
  match payload {
    EcsPayload_animation_AnimationClip(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for AnimationGraph with to_ecs_payload(self) {
  EcsPayload_animation_AnimationGraph(self)
}

///|
pub impl @ecs.EcsPayloadCodec for AnimationGraph with from_ecs_payload(payload) {
  match payload {
    EcsPayload_animation_AnimationGraph(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for AnimationGraphHandle with to_ecs_payload(self) {
  EcsPayload_animation_AnimationGraphHandle(self)
}

///|
pub impl @ecs.EcsPayloadCodec for AnimationGraphHandle with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_animation_AnimationGraphHandle(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for AnimationTransitions with to_ecs_payload(self) {
  EcsPayload_animation_AnimationTransitions(self)
}

///|
pub impl @ecs.EcsPayloadCodec for AnimationTransitions with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_animation_AnimationTransitions(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for AnimationWeights with to_ecs_payload(self) {
  EcsPayload_animation_AnimationWeights(self)
}

///|
pub impl @ecs.EcsPayloadCodec for AnimationWeights with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_animation_AnimationWeights(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for ThreadedAnimationGraphs with to_ecs_payload(self) {
  EcsPayload_animation_ThreadedAnimationGraphs(self)
}

///|
impl @ecs.EcsPayloadCodec for ThreadedAnimationGraphs with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_animation_ThreadedAnimationGraphs(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for AnimationRuntimeScratch with to_ecs_payload(self) {
  EcsPayload_animation_AnimationRuntimeScratch(self)
}

///|
impl @ecs.EcsPayloadCodec for AnimationRuntimeScratch with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_animation_AnimationRuntimeScratch(value) => Some(value)
    _ => None
  }
}
