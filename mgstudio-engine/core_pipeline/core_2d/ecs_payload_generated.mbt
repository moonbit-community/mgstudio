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
  EcsPayload_core_pipeline_core_2d_Opaque2dPhase(Opaque2dPhase)
  EcsPayload_core_pipeline_core_2d_AlphaMask2dPhase(AlphaMask2dPhase)
  EcsPayload_core_pipeline_core_2d_Transparent2dPhase(Transparent2dPhase)
}

///|
pub impl @ecs.EcsPayloadCodec for Opaque2dPhase with to_ecs_payload(self) {
  EcsPayload_core_pipeline_core_2d_Opaque2dPhase(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Opaque2dPhase with from_ecs_payload(payload) {
  match payload {
    EcsPayload_core_pipeline_core_2d_Opaque2dPhase(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for AlphaMask2dPhase with to_ecs_payload(self) {
  EcsPayload_core_pipeline_core_2d_AlphaMask2dPhase(self)
}

///|
pub impl @ecs.EcsPayloadCodec for AlphaMask2dPhase with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_core_pipeline_core_2d_AlphaMask2dPhase(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Transparent2dPhase with to_ecs_payload(self) {
  EcsPayload_core_pipeline_core_2d_Transparent2dPhase(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Transparent2dPhase with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_core_pipeline_core_2d_Transparent2dPhase(value) => Some(value)
    _ => None
  }
}
