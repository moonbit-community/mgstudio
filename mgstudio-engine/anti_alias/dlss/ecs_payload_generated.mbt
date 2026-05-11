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
  EcsPayload_anti_alias_dlss_Dlss(Dlss)
  EcsPayload_anti_alias_dlss_DlssProjectId(DlssProjectId)
  EcsPayload_anti_alias_dlss_DlssSuperResolutionSupported(
    DlssSuperResolutionSupported
  )
  EcsPayload_anti_alias_dlss_DlssRayReconstructionSupported(
    DlssRayReconstructionSupported
  )
  EcsPayload_anti_alias_dlss_DlssRuntimeState(DlssRuntimeState)
  EcsPayload_anti_alias_dlss_DlssInitPluginMarker(DlssInitPluginMarker)
}

///|
pub impl @ecs.EcsPayloadCodec for Dlss with to_ecs_payload(self) {
  EcsPayload_anti_alias_dlss_Dlss(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Dlss with from_ecs_payload(payload) {
  match payload {
    EcsPayload_anti_alias_dlss_Dlss(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for DlssProjectId with to_ecs_payload(self) {
  EcsPayload_anti_alias_dlss_DlssProjectId(self)
}

///|
pub impl @ecs.EcsPayloadCodec for DlssProjectId with from_ecs_payload(payload) {
  match payload {
    EcsPayload_anti_alias_dlss_DlssProjectId(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for DlssSuperResolutionSupported with to_ecs_payload(
  self,
) {
  EcsPayload_anti_alias_dlss_DlssSuperResolutionSupported(self)
}

///|
pub impl @ecs.EcsPayloadCodec for DlssSuperResolutionSupported with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_anti_alias_dlss_DlssSuperResolutionSupported(value) =>
      Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for DlssRayReconstructionSupported with to_ecs_payload(
  self,
) {
  EcsPayload_anti_alias_dlss_DlssRayReconstructionSupported(self)
}

///|
pub impl @ecs.EcsPayloadCodec for DlssRayReconstructionSupported with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_anti_alias_dlss_DlssRayReconstructionSupported(value) =>
      Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for DlssRuntimeState with to_ecs_payload(self) {
  EcsPayload_anti_alias_dlss_DlssRuntimeState(self)
}

///|
pub impl @ecs.EcsPayloadCodec for DlssRuntimeState with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_anti_alias_dlss_DlssRuntimeState(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for DlssInitPluginMarker with to_ecs_payload(self) {
  EcsPayload_anti_alias_dlss_DlssInitPluginMarker(self)
}

///|
impl @ecs.EcsPayloadCodec for DlssInitPluginMarker with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_anti_alias_dlss_DlssInitPluginMarker(value) => Some(value)
    _ => None
  }
}
