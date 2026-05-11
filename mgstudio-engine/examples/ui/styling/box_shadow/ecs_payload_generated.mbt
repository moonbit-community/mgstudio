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
  EcsPayload_examples_ui_styling_box_shadow_ShadowControlButton(
    ShadowControlButton
  )
  EcsPayload_examples_ui_styling_box_shadow_ShadowValueLabel(ShadowValueLabel)
  EcsPayload_examples_ui_styling_box_shadow_ShadowNode(ShadowNode)
  EcsPayload_examples_ui_styling_box_shadow_ShadowSettings(ShadowSettings)
  EcsPayload_examples_ui_styling_box_shadow_PressedControls(PressedControls)
}

///|
impl @ecs.EcsPayloadCodec for ShadowControlButton with to_ecs_payload(self) {
  EcsPayload_examples_ui_styling_box_shadow_ShadowControlButton(self)
}

///|
impl @ecs.EcsPayloadCodec for ShadowControlButton with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_ui_styling_box_shadow_ShadowControlButton(value) =>
      Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for ShadowValueLabel with to_ecs_payload(self) {
  EcsPayload_examples_ui_styling_box_shadow_ShadowValueLabel(self)
}

///|
impl @ecs.EcsPayloadCodec for ShadowValueLabel with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_ui_styling_box_shadow_ShadowValueLabel(value) =>
      Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for ShadowNode with to_ecs_payload(self) {
  EcsPayload_examples_ui_styling_box_shadow_ShadowNode(self)
}

///|
impl @ecs.EcsPayloadCodec for ShadowNode with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_ui_styling_box_shadow_ShadowNode(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for ShadowSettings with to_ecs_payload(self) {
  EcsPayload_examples_ui_styling_box_shadow_ShadowSettings(self)
}

///|
impl @ecs.EcsPayloadCodec for ShadowSettings with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_ui_styling_box_shadow_ShadowSettings(value) =>
      Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for PressedControls with to_ecs_payload(self) {
  EcsPayload_examples_ui_styling_box_shadow_PressedControls(self)
}

///|
impl @ecs.EcsPayloadCodec for PressedControls with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_ui_styling_box_shadow_PressedControls(value) =>
      Some(value)
    _ => None
  }
}
