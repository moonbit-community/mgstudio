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
  EcsPayload_input_AccumulatedMouseMotion(AccumulatedMouseMotion)
  EcsPayload_input_AccumulatedMouseScroll(AccumulatedMouseScroll)
  EcsPayload_input_Touches(Touches)
  EcsPayload_input_Gamepad(Gamepad)
  EcsPayload_input_GamepadSettings(GamepadSettings)
  EcsPayload_input_RunningRumbleEffects(RunningRumbleEffects)
  EcsPayload_input_GamepadEvent(GamepadEvent)
  EcsPayload_input_GamepadConnectionEvent(GamepadConnectionEvent)
  EcsPayload_input_RawGamepadAxisChangedEvent(RawGamepadAxisChangedEvent)
  EcsPayload_input_GamepadAxisChangedEvent(GamepadAxisChangedEvent)
  EcsPayload_input_RawGamepadButtonChangedEvent(RawGamepadButtonChangedEvent)
  EcsPayload_input_GamepadButtonChangedEvent(GamepadButtonChangedEvent)
  EcsPayload_input_GamepadButtonStateChangedEvent(
    GamepadButtonStateChangedEvent
  )
  EcsPayload_input_RawGamepadEvent(RawGamepadEvent)
  EcsPayload_input_GamepadRumbleRequest(GamepadRumbleRequest)
}

///|
pub impl @ecs.EcsPayloadCodec for AccumulatedMouseMotion with to_ecs_payload(
  self,
) {
  EcsPayload_input_AccumulatedMouseMotion(self)
}

///|
pub impl @ecs.EcsPayloadCodec for AccumulatedMouseMotion with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_input_AccumulatedMouseMotion(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for AccumulatedMouseScroll with to_ecs_payload(
  self,
) {
  EcsPayload_input_AccumulatedMouseScroll(self)
}

///|
pub impl @ecs.EcsPayloadCodec for AccumulatedMouseScroll with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_input_AccumulatedMouseScroll(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Touches with to_ecs_payload(self) {
  EcsPayload_input_Touches(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Touches with from_ecs_payload(payload) {
  match payload {
    EcsPayload_input_Touches(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Gamepad with to_ecs_payload(self) {
  EcsPayload_input_Gamepad(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Gamepad with from_ecs_payload(payload) {
  match payload {
    EcsPayload_input_Gamepad(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for GamepadSettings with to_ecs_payload(self) {
  EcsPayload_input_GamepadSettings(self)
}

///|
pub impl @ecs.EcsPayloadCodec for GamepadSettings with from_ecs_payload(payload) {
  match payload {
    EcsPayload_input_GamepadSettings(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for RunningRumbleEffects with to_ecs_payload(self) {
  EcsPayload_input_RunningRumbleEffects(self)
}

///|
pub impl @ecs.EcsPayloadCodec for RunningRumbleEffects with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_input_RunningRumbleEffects(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for GamepadEvent with to_ecs_payload(self) {
  EcsPayload_input_GamepadEvent(self)
}

///|
pub impl @ecs.EcsPayloadCodec for GamepadEvent with from_ecs_payload(payload) {
  match payload {
    EcsPayload_input_GamepadEvent(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for GamepadConnectionEvent with to_ecs_payload(
  self,
) {
  EcsPayload_input_GamepadConnectionEvent(self)
}

///|
pub impl @ecs.EcsPayloadCodec for GamepadConnectionEvent with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_input_GamepadConnectionEvent(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for RawGamepadAxisChangedEvent with to_ecs_payload(
  self,
) {
  EcsPayload_input_RawGamepadAxisChangedEvent(self)
}

///|
pub impl @ecs.EcsPayloadCodec for RawGamepadAxisChangedEvent with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_input_RawGamepadAxisChangedEvent(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for GamepadAxisChangedEvent with to_ecs_payload(
  self,
) {
  EcsPayload_input_GamepadAxisChangedEvent(self)
}

///|
pub impl @ecs.EcsPayloadCodec for GamepadAxisChangedEvent with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_input_GamepadAxisChangedEvent(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for RawGamepadButtonChangedEvent with to_ecs_payload(
  self,
) {
  EcsPayload_input_RawGamepadButtonChangedEvent(self)
}

///|
pub impl @ecs.EcsPayloadCodec for RawGamepadButtonChangedEvent with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_input_RawGamepadButtonChangedEvent(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for GamepadButtonChangedEvent with to_ecs_payload(
  self,
) {
  EcsPayload_input_GamepadButtonChangedEvent(self)
}

///|
pub impl @ecs.EcsPayloadCodec for GamepadButtonChangedEvent with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_input_GamepadButtonChangedEvent(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for GamepadButtonStateChangedEvent with to_ecs_payload(
  self,
) {
  EcsPayload_input_GamepadButtonStateChangedEvent(self)
}

///|
pub impl @ecs.EcsPayloadCodec for GamepadButtonStateChangedEvent with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_input_GamepadButtonStateChangedEvent(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for RawGamepadEvent with to_ecs_payload(self) {
  EcsPayload_input_RawGamepadEvent(self)
}

///|
pub impl @ecs.EcsPayloadCodec for RawGamepadEvent with from_ecs_payload(payload) {
  match payload {
    EcsPayload_input_RawGamepadEvent(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for GamepadRumbleRequest with to_ecs_payload(self) {
  EcsPayload_input_GamepadRumbleRequest(self)
}

///|
pub impl @ecs.EcsPayloadCodec for GamepadRumbleRequest with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_input_GamepadRumbleRequest(value) => Some(value)
    _ => None
  }
}
