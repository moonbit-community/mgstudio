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
  EcsPayload_core_pipeline_core_3d_Hdr(Hdr)
  EcsPayload_core_pipeline_core_3d_Msaa(Msaa)
  EcsPayload_core_pipeline_core_3d_Opaque3dPhase(Opaque3dPhase)
  EcsPayload_core_pipeline_core_3d_AlphaMask3dPhase(AlphaMask3dPhase)
  EcsPayload_core_pipeline_core_3d_Transparent3dPhase(Transparent3dPhase)
}

///|
pub impl @ecs.EcsPayloadCodec for Hdr with to_ecs_payload(self) {
  EcsPayload_core_pipeline_core_3d_Hdr(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Hdr with from_ecs_payload(payload) {
  match payload {
    EcsPayload_core_pipeline_core_3d_Hdr(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Msaa with to_ecs_payload(self) {
  EcsPayload_core_pipeline_core_3d_Msaa(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Msaa with from_ecs_payload(payload) {
  match payload {
    EcsPayload_core_pipeline_core_3d_Msaa(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Opaque3dPhase with to_ecs_payload(self) {
  EcsPayload_core_pipeline_core_3d_Opaque3dPhase(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Opaque3dPhase with from_ecs_payload(payload) {
  match payload {
    EcsPayload_core_pipeline_core_3d_Opaque3dPhase(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for AlphaMask3dPhase with to_ecs_payload(self) {
  EcsPayload_core_pipeline_core_3d_AlphaMask3dPhase(self)
}

///|
pub impl @ecs.EcsPayloadCodec for AlphaMask3dPhase with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_core_pipeline_core_3d_AlphaMask3dPhase(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Transparent3dPhase with to_ecs_payload(self) {
  EcsPayload_core_pipeline_core_3d_Transparent3dPhase(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Transparent3dPhase with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_core_pipeline_core_3d_Transparent3dPhase(value) => Some(value)
    _ => None
  }
}
