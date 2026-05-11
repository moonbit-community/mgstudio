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
  EcsPayload_render_diagnostic_ErasedRenderAssetDiagnosticState(
    ErasedRenderAssetDiagnosticState
  )
  EcsPayload_render_diagnostic_RenderAssetDiagnosticState(
    RenderAssetDiagnosticState
  )
  EcsPayload_render_diagnostic_MeshAllocatorDiagnosticState(
    MeshAllocatorDiagnosticState
  )
  EcsPayload_render_diagnostic_RenderDiagnosticsModuleState(
    RenderDiagnosticsModuleState
  )
}

///|
pub impl @ecs.EcsPayloadCodec for ErasedRenderAssetDiagnosticState with to_ecs_payload(
  self,
) {
  EcsPayload_render_diagnostic_ErasedRenderAssetDiagnosticState(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ErasedRenderAssetDiagnosticState with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_render_diagnostic_ErasedRenderAssetDiagnosticState(value) =>
      Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for RenderAssetDiagnosticState with to_ecs_payload(
  self,
) {
  EcsPayload_render_diagnostic_RenderAssetDiagnosticState(self)
}

///|
pub impl @ecs.EcsPayloadCodec for RenderAssetDiagnosticState with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_render_diagnostic_RenderAssetDiagnosticState(value) =>
      Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for MeshAllocatorDiagnosticState with to_ecs_payload(
  self,
) {
  EcsPayload_render_diagnostic_MeshAllocatorDiagnosticState(self)
}

///|
pub impl @ecs.EcsPayloadCodec for MeshAllocatorDiagnosticState with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_render_diagnostic_MeshAllocatorDiagnosticState(value) =>
      Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for RenderDiagnosticsModuleState with to_ecs_payload(
  self,
) {
  EcsPayload_render_diagnostic_RenderDiagnosticsModuleState(self)
}

///|
pub impl @ecs.EcsPayloadCodec for RenderDiagnosticsModuleState with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_render_diagnostic_RenderDiagnosticsModuleState(value) =>
      Some(value)
    _ => None
  }
}
