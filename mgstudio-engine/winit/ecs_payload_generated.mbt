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
  EcsPayload_winit_WinitSettings(WinitSettings)
  EcsPayload_winit_WinitMonitors(WinitMonitors)
  EcsPayload_winit_RawWinitWindowEvent(RawWinitWindowEvent)
  EcsPayload_winit_WinitWindows(WinitWindows)
}

///|
pub impl @ecs.EcsPayloadCodec for WinitSettings with to_ecs_payload(self) {
  EcsPayload_winit_WinitSettings(self)
}

///|
pub impl @ecs.EcsPayloadCodec for WinitSettings with from_ecs_payload(payload) {
  match payload {
    EcsPayload_winit_WinitSettings(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for WinitMonitors with to_ecs_payload(self) {
  EcsPayload_winit_WinitMonitors(self)
}

///|
pub impl @ecs.EcsPayloadCodec for WinitMonitors with from_ecs_payload(payload) {
  match payload {
    EcsPayload_winit_WinitMonitors(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for RawWinitWindowEvent with to_ecs_payload(self) {
  EcsPayload_winit_RawWinitWindowEvent(self)
}

///|
pub impl @ecs.EcsPayloadCodec for RawWinitWindowEvent with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_winit_RawWinitWindowEvent(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for WinitWindows with to_ecs_payload(self) {
  EcsPayload_winit_WinitWindows(self)
}

///|
pub impl @ecs.EcsPayloadCodec for WinitWindows with from_ecs_payload(payload) {
  match payload {
    EcsPayload_winit_WinitWindows(value) => Some(value)
    _ => None
  }
}
