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
  EcsPayload_input_focus_AutoNavigationConfig(AutoNavigationConfig)
  EcsPayload_input_focus_DirectionalNavigationMap(DirectionalNavigationMap)
  EcsPayload_input_focus_TabIndex(TabIndex)
  EcsPayload_input_focus_TabGroup(TabGroup)
  EcsPayload_input_focus_InputFocus(InputFocus)
  EcsPayload_input_focus_InputFocusVisible(InputFocusVisible)
  EcsPayload_input_focus_AutoFocus(AutoFocus)
  EcsPayload_input_focus_FocusedInput(FocusedInputPayload)
}

///|
pub(all) struct FocusedInputPayload {
  focused_entity : @core.Entity
  input : @ecs.EcsPayload
  window : @core.Entity
}

///|
pub impl @ecs.EcsPayloadCodec for AutoNavigationConfig with to_ecs_payload(self) {
  EcsPayload_input_focus_AutoNavigationConfig(self)
}

///|
pub impl @ecs.EcsPayloadCodec for AutoNavigationConfig with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_input_focus_AutoNavigationConfig(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for DirectionalNavigationMap with to_ecs_payload(
  self,
) {
  EcsPayload_input_focus_DirectionalNavigationMap(self)
}

///|
pub impl @ecs.EcsPayloadCodec for DirectionalNavigationMap with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_input_focus_DirectionalNavigationMap(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for TabIndex with to_ecs_payload(self) {
  EcsPayload_input_focus_TabIndex(self)
}

///|
pub impl @ecs.EcsPayloadCodec for TabIndex with from_ecs_payload(payload) {
  match payload {
    EcsPayload_input_focus_TabIndex(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for TabGroup with to_ecs_payload(self) {
  EcsPayload_input_focus_TabGroup(self)
}

///|
pub impl @ecs.EcsPayloadCodec for TabGroup with from_ecs_payload(payload) {
  match payload {
    EcsPayload_input_focus_TabGroup(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for InputFocus with to_ecs_payload(self) {
  EcsPayload_input_focus_InputFocus(self)
}

///|
pub impl @ecs.EcsPayloadCodec for InputFocus with from_ecs_payload(payload) {
  match payload {
    EcsPayload_input_focus_InputFocus(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for InputFocusVisible with to_ecs_payload(self) {
  EcsPayload_input_focus_InputFocusVisible(self)
}

///|
pub impl @ecs.EcsPayloadCodec for InputFocusVisible with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_input_focus_InputFocusVisible(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for AutoFocus with to_ecs_payload(self) {
  EcsPayload_input_focus_AutoFocus(self)
}

///|
pub impl @ecs.EcsPayloadCodec for AutoFocus with from_ecs_payload(payload) {
  match payload {
    EcsPayload_input_focus_AutoFocus(value) => Some(value)
    _ => None
  }
}

///|
pub impl[M : @ecs.EcsPayloadCodec] @ecs.EcsPayloadCodec for FocusedInput[M] with to_ecs_payload(
  self,
) {
  EcsPayload_input_focus_FocusedInput(FocusedInputPayload::{
    focused_entity: self.focused_entity,
    input: M::to_ecs_payload(self.input),
    window: self.window,
  })
}

///|
pub impl[M : @ecs.EcsPayloadCodec] @ecs.EcsPayloadCodec for FocusedInput[M] with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_input_focus_FocusedInput(value) =>
      match M::from_ecs_payload(value.input) {
        Some(input) =>
          Some(FocusedInput::{
            focused_entity: value.focused_entity,
            input,
            window: value.window,
          })
        None => None
      }
    _ => None
  }
}
