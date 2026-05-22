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
  EcsPayload_diagnostic_FrameCount(FrameCount)
  EcsPayload_diagnostic_DiagnosticsStore(DiagnosticsStore)
  EcsPayload_diagnostic_SystemInfo(SystemInfo)
  EcsPayload_diagnostic_LogDiagnosticsState(LogDiagnosticsState)
}

///|
pub impl @ecs.EcsPayloadCodec for FrameCount with to_ecs_payload(self) {
  EcsPayload_diagnostic_FrameCount(self)
}

///|
pub impl @ecs.EcsPayloadCodec for FrameCount with from_ecs_payload(payload) {
  match payload {
    EcsPayload_diagnostic_FrameCount(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for DiagnosticsStore with to_ecs_payload(self) {
  EcsPayload_diagnostic_DiagnosticsStore(self)
}

///|
pub impl @ecs.EcsPayloadCodec for DiagnosticsStore with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_diagnostic_DiagnosticsStore(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for SystemInfo with to_ecs_payload(self) {
  EcsPayload_diagnostic_SystemInfo(self)
}

///|
pub impl @ecs.EcsPayloadCodec for SystemInfo with from_ecs_payload(payload) {
  match payload {
    EcsPayload_diagnostic_SystemInfo(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for LogDiagnosticsState with to_ecs_payload(self) {
  EcsPayload_diagnostic_LogDiagnosticsState(self)
}

///|
pub impl @ecs.EcsPayloadCodec for LogDiagnosticsState with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_diagnostic_LogDiagnosticsState(value) => Some(value)
    _ => None
  }
}
