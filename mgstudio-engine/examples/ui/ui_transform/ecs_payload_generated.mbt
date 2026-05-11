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
  EcsPayload_examples_ui_ui_transform_RotateButton(RotateButton)
  EcsPayload_examples_ui_ui_transform_ScaleButton(ScaleButton)
  EcsPayload_examples_ui_ui_transform_TargetNode(TargetNode)
  EcsPayload_examples_ui_ui_transform_ControlButton(ControlButton)
  EcsPayload_examples_ui_ui_transform_ButtonPressState(ButtonPressState)
}

///|
impl @ecs.EcsPayloadCodec for RotateButton with to_ecs_payload(self) {
  EcsPayload_examples_ui_ui_transform_RotateButton(self)
}

///|
impl @ecs.EcsPayloadCodec for RotateButton with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_ui_ui_transform_RotateButton(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for ScaleButton with to_ecs_payload(self) {
  EcsPayload_examples_ui_ui_transform_ScaleButton(self)
}

///|
impl @ecs.EcsPayloadCodec for ScaleButton with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_ui_ui_transform_ScaleButton(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for TargetNode with to_ecs_payload(self) {
  EcsPayload_examples_ui_ui_transform_TargetNode(self)
}

///|
impl @ecs.EcsPayloadCodec for TargetNode with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_ui_ui_transform_TargetNode(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for ControlButton with to_ecs_payload(self) {
  EcsPayload_examples_ui_ui_transform_ControlButton(self)
}

///|
impl @ecs.EcsPayloadCodec for ControlButton with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_ui_ui_transform_ControlButton(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for ButtonPressState with to_ecs_payload(self) {
  EcsPayload_examples_ui_ui_transform_ButtonPressState(self)
}

///|
impl @ecs.EcsPayloadCodec for ButtonPressState with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_ui_ui_transform_ButtonPressState(value) => Some(value)
    _ => None
  }
}
