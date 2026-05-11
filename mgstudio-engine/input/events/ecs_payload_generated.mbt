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
  EcsPayload_input_events_KeyboardInput(KeyboardInput)
  EcsPayload_input_events_KeyboardCharacter(KeyboardCharacter)
  EcsPayload_input_events_KeyboardFocusLost(KeyboardFocusLost)
  EcsPayload_input_events_MouseButtonInput(MouseButtonInput)
  EcsPayload_input_events_MouseMotion(MouseMotion)
  EcsPayload_input_events_MouseWheel(MouseWheel)
  EcsPayload_input_events_PinchGesture(PinchGesture)
  EcsPayload_input_events_RotationGesture(RotationGesture)
  EcsPayload_input_events_DoubleTapGesture(DoubleTapGesture)
  EcsPayload_input_events_PanGesture(PanGesture)
  EcsPayload_input_events_TouchInput(TouchInput)
}

///|
pub impl @ecs.EcsPayloadCodec for KeyboardInput with to_ecs_payload(self) {
  EcsPayload_input_events_KeyboardInput(self)
}

///|
pub impl @ecs.EcsPayloadCodec for KeyboardInput with from_ecs_payload(payload) {
  match payload {
    EcsPayload_input_events_KeyboardInput(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for KeyboardCharacter with to_ecs_payload(self) {
  EcsPayload_input_events_KeyboardCharacter(self)
}

///|
pub impl @ecs.EcsPayloadCodec for KeyboardCharacter with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_input_events_KeyboardCharacter(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for KeyboardFocusLost with to_ecs_payload(self) {
  EcsPayload_input_events_KeyboardFocusLost(self)
}

///|
pub impl @ecs.EcsPayloadCodec for KeyboardFocusLost with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_input_events_KeyboardFocusLost(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for MouseButtonInput with to_ecs_payload(self) {
  EcsPayload_input_events_MouseButtonInput(self)
}

///|
pub impl @ecs.EcsPayloadCodec for MouseButtonInput with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_input_events_MouseButtonInput(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for MouseMotion with to_ecs_payload(self) {
  EcsPayload_input_events_MouseMotion(self)
}

///|
pub impl @ecs.EcsPayloadCodec for MouseMotion with from_ecs_payload(payload) {
  match payload {
    EcsPayload_input_events_MouseMotion(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for MouseWheel with to_ecs_payload(self) {
  EcsPayload_input_events_MouseWheel(self)
}

///|
pub impl @ecs.EcsPayloadCodec for MouseWheel with from_ecs_payload(payload) {
  match payload {
    EcsPayload_input_events_MouseWheel(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for PinchGesture with to_ecs_payload(self) {
  EcsPayload_input_events_PinchGesture(self)
}

///|
pub impl @ecs.EcsPayloadCodec for PinchGesture with from_ecs_payload(payload) {
  match payload {
    EcsPayload_input_events_PinchGesture(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for RotationGesture with to_ecs_payload(self) {
  EcsPayload_input_events_RotationGesture(self)
}

///|
pub impl @ecs.EcsPayloadCodec for RotationGesture with from_ecs_payload(payload) {
  match payload {
    EcsPayload_input_events_RotationGesture(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for DoubleTapGesture with to_ecs_payload(self) {
  EcsPayload_input_events_DoubleTapGesture(self)
}

///|
pub impl @ecs.EcsPayloadCodec for DoubleTapGesture with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_input_events_DoubleTapGesture(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for PanGesture with to_ecs_payload(self) {
  EcsPayload_input_events_PanGesture(self)
}

///|
pub impl @ecs.EcsPayloadCodec for PanGesture with from_ecs_payload(payload) {
  match payload {
    EcsPayload_input_events_PanGesture(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for TouchInput with to_ecs_payload(self) {
  EcsPayload_input_events_TouchInput(self)
}

///|
pub impl @ecs.EcsPayloadCodec for TouchInput with from_ecs_payload(payload) {
  match payload {
    EcsPayload_input_events_TouchInput(value) => Some(value)
    _ => None
  }
}
