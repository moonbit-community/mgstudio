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
  EcsPayload_examples_animation_animation_masks_AnimationControl(
    AnimationControl
  )
  EcsPayload_examples_animation_animation_masks_AnimationMaskSetup(
    AnimationMaskSetup
  )
  EcsPayload_examples_animation_animation_masks_AnimationMaskState(
    AnimationMaskState
  )
  EcsPayload_examples_animation_animation_masks_PressedControls(PressedControls)
}

///|
impl @ecs.EcsPayloadCodec for AnimationControl with to_ecs_payload(self) {
  EcsPayload_examples_animation_animation_masks_AnimationControl(self)
}

///|
impl @ecs.EcsPayloadCodec for AnimationControl with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_animation_animation_masks_AnimationControl(value) =>
      Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for AnimationMaskSetup with to_ecs_payload(self) {
  EcsPayload_examples_animation_animation_masks_AnimationMaskSetup(self)
}

///|
impl @ecs.EcsPayloadCodec for AnimationMaskSetup with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_animation_animation_masks_AnimationMaskSetup(value) =>
      Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for AnimationMaskState with to_ecs_payload(self) {
  EcsPayload_examples_animation_animation_masks_AnimationMaskState(self)
}

///|
impl @ecs.EcsPayloadCodec for AnimationMaskState with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_animation_animation_masks_AnimationMaskState(value) =>
      Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for PressedControls with to_ecs_payload(self) {
  EcsPayload_examples_animation_animation_masks_PressedControls(self)
}

///|
impl @ecs.EcsPayloadCodec for PressedControls with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_animation_animation_masks_PressedControls(value) =>
      Some(value)
    _ => None
  }
}
