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
  EcsPayload_examples_diagnostics_log_diagnostics_LogDiagnosticsStatus(
    LogDiagnosticsStatus
  )
  EcsPayload_examples_diagnostics_log_diagnostics_LogDiagnosticsFilters(
    LogDiagnosticsFilters
  )
  EcsPayload_examples_diagnostics_log_diagnostics_LogDiagnosticsCommandsText(
    LogDiagnosticsCommandsText
  )
}

///|
impl @ecs.EcsPayloadCodec for LogDiagnosticsStatus with to_ecs_payload(self) {
  EcsPayload_examples_diagnostics_log_diagnostics_LogDiagnosticsStatus(self)
}

///|
impl @ecs.EcsPayloadCodec for LogDiagnosticsStatus with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_examples_diagnostics_log_diagnostics_LogDiagnosticsStatus(value) =>
      Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for LogDiagnosticsFilters with to_ecs_payload(self) {
  EcsPayload_examples_diagnostics_log_diagnostics_LogDiagnosticsFilters(self)
}

///|
impl @ecs.EcsPayloadCodec for LogDiagnosticsFilters with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_examples_diagnostics_log_diagnostics_LogDiagnosticsFilters(value) =>
      Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for LogDiagnosticsCommandsText with to_ecs_payload(
  self,
) {
  EcsPayload_examples_diagnostics_log_diagnostics_LogDiagnosticsCommandsText(
    self,
  )
}

///|
impl @ecs.EcsPayloadCodec for LogDiagnosticsCommandsText with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_examples_diagnostics_log_diagnostics_LogDiagnosticsCommandsText(
      value
    ) => Some(value)
    _ => None
  }
}
