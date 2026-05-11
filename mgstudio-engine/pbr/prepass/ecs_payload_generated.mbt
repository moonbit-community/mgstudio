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
  EcsPayload_pbr_prepass_AnyPrepassPluginLoaded(AnyPrepassPluginLoaded)
  EcsPayload_pbr_prepass_PrepassPipelineState(PrepassPipelineState)
  EcsPayload_pbr_prepass_PreviousViewData(PreviousViewData)
  EcsPayload_pbr_prepass_PreviousGlobalTransform(PreviousGlobalTransform)
}

///|
pub impl @ecs.EcsPayloadCodec for AnyPrepassPluginLoaded with to_ecs_payload(
  self,
) {
  EcsPayload_pbr_prepass_AnyPrepassPluginLoaded(self)
}

///|
pub impl @ecs.EcsPayloadCodec for AnyPrepassPluginLoaded with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_pbr_prepass_AnyPrepassPluginLoaded(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for PrepassPipelineState with to_ecs_payload(self) {
  EcsPayload_pbr_prepass_PrepassPipelineState(self)
}

///|
pub impl @ecs.EcsPayloadCodec for PrepassPipelineState with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_pbr_prepass_PrepassPipelineState(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for PreviousViewData with to_ecs_payload(self) {
  EcsPayload_pbr_prepass_PreviousViewData(self)
}

///|
pub impl @ecs.EcsPayloadCodec for PreviousViewData with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_pbr_prepass_PreviousViewData(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for PreviousGlobalTransform with to_ecs_payload(
  self,
) {
  EcsPayload_pbr_prepass_PreviousGlobalTransform(self)
}

///|
pub impl @ecs.EcsPayloadCodec for PreviousGlobalTransform with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_pbr_prepass_PreviousGlobalTransform(value) => Some(value)
    _ => None
  }
}
