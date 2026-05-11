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
  EcsPayload_examples_state_custom_transitions_AppState(AppState)
  EcsPayload_examples_state_custom_transitions_MenuData(MenuData)
}

///|
impl @ecs.EcsPayloadCodec for AppState with to_ecs_payload(self) {
  EcsPayload_examples_state_custom_transitions_AppState(self)
}

///|
impl @ecs.EcsPayloadCodec for AppState with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_state_custom_transitions_AppState(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for MenuData with to_ecs_payload(self) {
  EcsPayload_examples_state_custom_transitions_MenuData(self)
}

///|
impl @ecs.EcsPayloadCodec for MenuData with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_state_custom_transitions_MenuData(value) => Some(value)
    _ => None
  }
}
