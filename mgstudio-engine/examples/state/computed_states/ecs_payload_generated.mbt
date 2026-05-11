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
  EcsPayload_examples_state_computed_states_AppState(AppState)
  EcsPayload_examples_state_computed_states_TutorialState(TutorialState)
  EcsPayload_examples_state_computed_states_InGame(InGame)
  EcsPayload_examples_state_computed_states_TurboMode(TurboMode)
  EcsPayload_examples_state_computed_states_IsPaused(IsPaused)
  EcsPayload_examples_state_computed_states_Tutorial(Tutorial)
  EcsPayload_examples_state_computed_states_MenuButton(MenuButton)
  EcsPayload_examples_state_computed_states_MenuData(MenuData)
}

///|
impl @ecs.EcsPayloadCodec for AppState with to_ecs_payload(self) {
  EcsPayload_examples_state_computed_states_AppState(self)
}

///|
impl @ecs.EcsPayloadCodec for AppState with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_state_computed_states_AppState(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for TutorialState with to_ecs_payload(self) {
  EcsPayload_examples_state_computed_states_TutorialState(self)
}

///|
impl @ecs.EcsPayloadCodec for TutorialState with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_state_computed_states_TutorialState(value) =>
      Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for InGame with to_ecs_payload(self) {
  EcsPayload_examples_state_computed_states_InGame(self)
}

///|
impl @ecs.EcsPayloadCodec for InGame with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_state_computed_states_InGame(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for TurboMode with to_ecs_payload(self) {
  EcsPayload_examples_state_computed_states_TurboMode(self)
}

///|
impl @ecs.EcsPayloadCodec for TurboMode with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_state_computed_states_TurboMode(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for IsPaused with to_ecs_payload(self) {
  EcsPayload_examples_state_computed_states_IsPaused(self)
}

///|
impl @ecs.EcsPayloadCodec for IsPaused with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_state_computed_states_IsPaused(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for Tutorial with to_ecs_payload(self) {
  EcsPayload_examples_state_computed_states_Tutorial(self)
}

///|
impl @ecs.EcsPayloadCodec for Tutorial with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_state_computed_states_Tutorial(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for MenuButton with to_ecs_payload(self) {
  EcsPayload_examples_state_computed_states_MenuButton(self)
}

///|
impl @ecs.EcsPayloadCodec for MenuButton with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_state_computed_states_MenuButton(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for MenuData with to_ecs_payload(self) {
  EcsPayload_examples_state_computed_states_MenuData(self)
}

///|
impl @ecs.EcsPayloadCodec for MenuData with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_state_computed_states_MenuData(value) => Some(value)
    _ => None
  }
}
