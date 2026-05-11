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
  EcsPayload_examples_helpers_widgets_lib_RadioButton(RadioButton)
  EcsPayload_examples_helpers_widgets_lib_RadioButtonText(RadioButtonText)
  EcsPayload_examples_helpers_widgets_lib_WidgetClickEvent(
    WidgetClickEventPayload
  )
  EcsPayload_examples_helpers_widgets_lib_WidgetClickSender(
    WidgetClickSenderPayload
  )
}

///|
pub(all) struct WidgetClickEventPayload {
  value : @ecs.EcsPayload
}

///|
pub(all) struct WidgetClickSenderPayload {
  value : @ecs.EcsPayload
}

///|
pub impl @ecs.EcsPayloadCodec for RadioButton with to_ecs_payload(self) {
  EcsPayload_examples_helpers_widgets_lib_RadioButton(self)
}

///|
pub impl @ecs.EcsPayloadCodec for RadioButton with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_helpers_widgets_lib_RadioButton(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for RadioButtonText with to_ecs_payload(self) {
  EcsPayload_examples_helpers_widgets_lib_RadioButtonText(self)
}

///|
pub impl @ecs.EcsPayloadCodec for RadioButtonText with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_helpers_widgets_lib_RadioButtonText(value) =>
      Some(value)
    _ => None
  }
}

///|
pub impl[T : @ecs.EcsPayloadCodec] @ecs.EcsPayloadCodec for WidgetClickEvent[T] with to_ecs_payload(
  self,
) {
  EcsPayload_examples_helpers_widgets_lib_WidgetClickEvent(WidgetClickEventPayload::{
    value: T::to_ecs_payload(self.value),
  })
}

///|
pub impl[T : @ecs.EcsPayloadCodec] @ecs.EcsPayloadCodec for WidgetClickEvent[T] with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_examples_helpers_widgets_lib_WidgetClickEvent(value) =>
      match T::from_ecs_payload(value.value) {
        Some(decoded) => Some(WidgetClickEvent::{ value: decoded })
        None => None
      }
    _ => None
  }
}

///|
pub impl[T : @ecs.EcsPayloadCodec] @ecs.EcsPayloadCodec for WidgetClickSender[T] with to_ecs_payload(
  self,
) {
  EcsPayload_examples_helpers_widgets_lib_WidgetClickSender(WidgetClickSenderPayload::{
    value: T::to_ecs_payload(self.value),
  })
}

///|
pub impl[T : @ecs.EcsPayloadCodec] @ecs.EcsPayloadCodec for WidgetClickSender[T] with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_examples_helpers_widgets_lib_WidgetClickSender(value) =>
      match T::from_ecs_payload(value.value) {
        Some(decoded) => Some(WidgetClickSender::{ value: decoded })
        None => None
      }
    _ => None
  }
}
