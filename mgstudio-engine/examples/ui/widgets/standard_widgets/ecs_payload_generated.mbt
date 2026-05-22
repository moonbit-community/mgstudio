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
  EcsPayload_examples_ui_widgets_standard_widgets_ToggleButton(ToggleButton)
  EcsPayload_examples_ui_widgets_standard_widgets_ToggleLabel(ToggleLabel)
  EcsPayload_examples_ui_widgets_standard_widgets_WidgetSlider(WidgetSlider)
  EcsPayload_examples_ui_widgets_standard_widgets_WidgetSliderFill(
    WidgetSliderFill
  )
}

///|
impl @ecs.EcsPayloadCodec for ToggleButton with to_ecs_payload(self) {
  EcsPayload_examples_ui_widgets_standard_widgets_ToggleButton(self)
}

///|
impl @ecs.EcsPayloadCodec for ToggleButton with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_ui_widgets_standard_widgets_ToggleButton(value) =>
      Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for ToggleLabel with to_ecs_payload(self) {
  EcsPayload_examples_ui_widgets_standard_widgets_ToggleLabel(self)
}

///|
impl @ecs.EcsPayloadCodec for ToggleLabel with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_ui_widgets_standard_widgets_ToggleLabel(value) =>
      Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for WidgetSlider with to_ecs_payload(self) {
  EcsPayload_examples_ui_widgets_standard_widgets_WidgetSlider(self)
}

///|
impl @ecs.EcsPayloadCodec for WidgetSlider with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_ui_widgets_standard_widgets_WidgetSlider(value) =>
      Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for WidgetSliderFill with to_ecs_payload(self) {
  EcsPayload_examples_ui_widgets_standard_widgets_WidgetSliderFill(self)
}

///|
impl @ecs.EcsPayloadCodec for WidgetSliderFill with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_ui_widgets_standard_widgets_WidgetSliderFill(value) =>
      Some(value)
    _ => None
  }
}
