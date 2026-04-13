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
pub let ecs_components : Array[String] = ["AccessibilityNode"]

///|
pub let ecs_resources : Array[String] = [
  "AccessibilityRequested", "ManageAccessibilityUpdates",
]

///|
pub let ecs_messages : Array[String] = ["ActionRequest"]

///|
pub let ecs_key_accessibility_node : @ecs.ComponentKey[AccessibilityNode] = @ecs.register_component(
  debug_name="mgstudio_a11y::AccessibilityNode",
)

///|
pub let ecs_res_key_accessibility_requested : @ecs.ResourceKey[
  AccessibilityRequested,
] = @ecs.register_resource(debug_name="mgstudio_a11y::AccessibilityRequested")

///|
pub let ecs_res_key_manage_accessibility_updates : @ecs.ResourceKey[
  ManageAccessibilityUpdates,
] = @ecs.register_resource(
  debug_name="mgstudio_a11y::ManageAccessibilityUpdates",
)

///|
pub let ecs_msg_key_action_request : @ecs.MessageKey[ActionRequest] = @ecs.register_message(
  debug_name="mgstudio_a11y::ActionRequest",
)

///|
pub impl @ecs.Component for AccessibilityNode with component() {
  ecs_key_accessibility_node
}

///|
pub impl @ecs.Message for ActionRequest with message() {
  ecs_msg_key_action_request
}

///|
pub impl @app.Resource for AccessibilityRequested with resource() {
  ecs_res_key_accessibility_requested
}

///|
pub impl @app.Resource for ManageAccessibilityUpdates with resource() {
  ecs_res_key_manage_accessibility_updates
}

///|
pub fn get_accessibility_requested_resource(
  world : @ecs.World,
) -> @ecs.ResourceAccess[AccessibilityRequested] {
  world.resource(ecs_res_key_accessibility_requested)
}

///|
pub fn get_manage_accessibility_updates_resource(
  world : @ecs.World,
) -> @ecs.ResourceAccess[ManageAccessibilityUpdates] {
  world.resource(ecs_res_key_manage_accessibility_updates)
}
