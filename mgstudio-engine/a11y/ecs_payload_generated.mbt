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
  EcsPayload_a11y_AccessibilityNode(AccessibilityNode)
  EcsPayload_a11y_ActionRequest(ActionRequest)
  EcsPayload_a11y_AccessibilityRequested(AccessibilityRequested)
  EcsPayload_a11y_ManageAccessibilityUpdates(ManageAccessibilityUpdates)
}

///|
pub impl @ecs.EcsPayloadCodec for AccessibilityNode with to_ecs_payload(self) {
  EcsPayload_a11y_AccessibilityNode(self)
}

///|
pub impl @ecs.EcsPayloadCodec for AccessibilityNode with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_a11y_AccessibilityNode(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ActionRequest with to_ecs_payload(self) {
  EcsPayload_a11y_ActionRequest(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ActionRequest with from_ecs_payload(payload) {
  match payload {
    EcsPayload_a11y_ActionRequest(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for AccessibilityRequested with to_ecs_payload(
  self,
) {
  EcsPayload_a11y_AccessibilityRequested(self)
}

///|
pub impl @ecs.EcsPayloadCodec for AccessibilityRequested with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_a11y_AccessibilityRequested(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ManageAccessibilityUpdates with to_ecs_payload(
  self,
) {
  EcsPayload_a11y_ManageAccessibilityUpdates(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ManageAccessibilityUpdates with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_a11y_ManageAccessibilityUpdates(value) => Some(value)
    _ => None
  }
}
