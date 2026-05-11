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
  EcsPayload_examples_ui_widgets_vertical_slider_VerticalFill(VerticalFill)
  EcsPayload_examples_ui_widgets_vertical_slider_HorizontalFill(HorizontalFill)
  EcsPayload_examples_ui_widgets_vertical_slider_SliderValues(SliderValues)
}

///|
impl @ecs.EcsPayloadCodec for VerticalFill with to_ecs_payload(self) {
  EcsPayload_examples_ui_widgets_vertical_slider_VerticalFill(self)
}

///|
impl @ecs.EcsPayloadCodec for VerticalFill with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_ui_widgets_vertical_slider_VerticalFill(value) =>
      Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for HorizontalFill with to_ecs_payload(self) {
  EcsPayload_examples_ui_widgets_vertical_slider_HorizontalFill(self)
}

///|
impl @ecs.EcsPayloadCodec for HorizontalFill with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_ui_widgets_vertical_slider_HorizontalFill(value) =>
      Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for SliderValues with to_ecs_payload(self) {
  EcsPayload_examples_ui_widgets_vertical_slider_SliderValues(self)
}

///|
impl @ecs.EcsPayloadCodec for SliderValues with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_ui_widgets_vertical_slider_SliderValues(value) =>
      Some(value)
    _ => None
  }
}
