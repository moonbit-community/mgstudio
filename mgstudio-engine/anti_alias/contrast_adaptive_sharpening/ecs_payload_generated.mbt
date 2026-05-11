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
  EcsPayload_anti_alias_contrast_adaptive_sharpening_ContrastAdaptiveSharpening(
    ContrastAdaptiveSharpening
  )
  EcsPayload_anti_alias_contrast_adaptive_sharpening_DenoiseCas(DenoiseCas)
  EcsPayload_anti_alias_contrast_adaptive_sharpening_CasUniform(CasUniform)
  EcsPayload_anti_alias_contrast_adaptive_sharpening_CasRuntimeState(
    CasRuntimeState
  )
}

///|
pub impl @ecs.EcsPayloadCodec for ContrastAdaptiveSharpening with to_ecs_payload(
  self,
) {
  EcsPayload_anti_alias_contrast_adaptive_sharpening_ContrastAdaptiveSharpening(
    self,
  )
}

///|
pub impl @ecs.EcsPayloadCodec for ContrastAdaptiveSharpening with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_anti_alias_contrast_adaptive_sharpening_ContrastAdaptiveSharpening(
      value
    ) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for DenoiseCas with to_ecs_payload(self) {
  EcsPayload_anti_alias_contrast_adaptive_sharpening_DenoiseCas(self)
}

///|
pub impl @ecs.EcsPayloadCodec for DenoiseCas with from_ecs_payload(payload) {
  match payload {
    EcsPayload_anti_alias_contrast_adaptive_sharpening_DenoiseCas(value) =>
      Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for CasUniform with to_ecs_payload(self) {
  EcsPayload_anti_alias_contrast_adaptive_sharpening_CasUniform(self)
}

///|
pub impl @ecs.EcsPayloadCodec for CasUniform with from_ecs_payload(payload) {
  match payload {
    EcsPayload_anti_alias_contrast_adaptive_sharpening_CasUniform(value) =>
      Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for CasRuntimeState with to_ecs_payload(self) {
  EcsPayload_anti_alias_contrast_adaptive_sharpening_CasRuntimeState(self)
}

///|
pub impl @ecs.EcsPayloadCodec for CasRuntimeState with from_ecs_payload(payload) {
  match payload {
    EcsPayload_anti_alias_contrast_adaptive_sharpening_CasRuntimeState(value) =>
      Some(value)
    _ => None
  }
}
