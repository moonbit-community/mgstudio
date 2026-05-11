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
  EcsPayload_examples_ui_navigation_directional_navigation_NavButton(NavButton)
  EcsPayload_examples_ui_navigation_directional_navigation_ActivatedButton(
    ActivatedButton
  )
  EcsPayload_examples_ui_navigation_directional_navigation_FocusDisplay(
    FocusDisplay
  )
  EcsPayload_examples_ui_navigation_directional_navigation_LastInputDisplay(
    LastInputDisplay
  )
  EcsPayload_examples_ui_navigation_directional_navigation_NavigationStatus(
    NavigationStatus
  )
}

///|
impl @ecs.EcsPayloadCodec for NavButton with to_ecs_payload(self) {
  EcsPayload_examples_ui_navigation_directional_navigation_NavButton(self)
}

///|
impl @ecs.EcsPayloadCodec for NavButton with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_ui_navigation_directional_navigation_NavButton(value) =>
      Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for ActivatedButton with to_ecs_payload(self) {
  EcsPayload_examples_ui_navigation_directional_navigation_ActivatedButton(self)
}

///|
impl @ecs.EcsPayloadCodec for ActivatedButton with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_ui_navigation_directional_navigation_ActivatedButton(
      value
    ) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for FocusDisplay with to_ecs_payload(self) {
  EcsPayload_examples_ui_navigation_directional_navigation_FocusDisplay(self)
}

///|
impl @ecs.EcsPayloadCodec for FocusDisplay with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_ui_navigation_directional_navigation_FocusDisplay(value) =>
      Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for LastInputDisplay with to_ecs_payload(self) {
  EcsPayload_examples_ui_navigation_directional_navigation_LastInputDisplay(
    self,
  )
}

///|
impl @ecs.EcsPayloadCodec for LastInputDisplay with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_ui_navigation_directional_navigation_LastInputDisplay(
      value
    ) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for NavigationStatus with to_ecs_payload(self) {
  EcsPayload_examples_ui_navigation_directional_navigation_NavigationStatus(
    self,
  )
}

///|
impl @ecs.EcsPayloadCodec for NavigationStatus with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_ui_navigation_directional_navigation_NavigationStatus(
      value
    ) => Some(value)
    _ => None
  }
}
