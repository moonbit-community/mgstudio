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
  EcsPayload_examples_ui_navigation_directional_navigation_overrides_OverrideButton(
    OverrideButton
  )
  EcsPayload_examples_ui_navigation_directional_navigation_overrides_OverrideState(
    OverrideState
  )
  EcsPayload_examples_ui_navigation_directional_navigation_overrides_OverrideFocusDisplay(
    OverrideFocusDisplay
  )
  EcsPayload_examples_ui_navigation_directional_navigation_overrides_OverrideLastInputDisplay(
    OverrideLastInputDisplay
  )
  EcsPayload_examples_ui_navigation_directional_navigation_overrides_OverrideStatus(
    OverrideStatus
  )
}

///|
impl @ecs.EcsPayloadCodec for OverrideButton with to_ecs_payload(self) {
  EcsPayload_examples_ui_navigation_directional_navigation_overrides_OverrideButton(
    self,
  )
}

///|
impl @ecs.EcsPayloadCodec for OverrideButton with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_ui_navigation_directional_navigation_overrides_OverrideButton(
      value
    ) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for OverrideState with to_ecs_payload(self) {
  EcsPayload_examples_ui_navigation_directional_navigation_overrides_OverrideState(
    self,
  )
}

///|
impl @ecs.EcsPayloadCodec for OverrideState with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_ui_navigation_directional_navigation_overrides_OverrideState(
      value
    ) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for OverrideFocusDisplay with to_ecs_payload(self) {
  EcsPayload_examples_ui_navigation_directional_navigation_overrides_OverrideFocusDisplay(
    self,
  )
}

///|
impl @ecs.EcsPayloadCodec for OverrideFocusDisplay with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_examples_ui_navigation_directional_navigation_overrides_OverrideFocusDisplay(
      value
    ) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for OverrideLastInputDisplay with to_ecs_payload(self) {
  EcsPayload_examples_ui_navigation_directional_navigation_overrides_OverrideLastInputDisplay(
    self,
  )
}

///|
impl @ecs.EcsPayloadCodec for OverrideLastInputDisplay with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_examples_ui_navigation_directional_navigation_overrides_OverrideLastInputDisplay(
      value
    ) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for OverrideStatus with to_ecs_payload(self) {
  EcsPayload_examples_ui_navigation_directional_navigation_overrides_OverrideStatus(
    self,
  )
}

///|
impl @ecs.EcsPayloadCodec for OverrideStatus with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_ui_navigation_directional_navigation_overrides_OverrideStatus(
      value
    ) => Some(value)
    _ => None
  }
}
