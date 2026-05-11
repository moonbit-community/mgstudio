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
  EcsPayload_core_pipeline_prepass_DepthPrepass(DepthPrepass)
  EcsPayload_core_pipeline_prepass_NormalPrepass(NormalPrepass)
  EcsPayload_core_pipeline_prepass_MotionVectorPrepass(MotionVectorPrepass)
  EcsPayload_core_pipeline_prepass_PrepassViewState(PrepassViewState)
}

///|
pub impl @ecs.EcsPayloadCodec for DepthPrepass with to_ecs_payload(self) {
  EcsPayload_core_pipeline_prepass_DepthPrepass(self)
}

///|
pub impl @ecs.EcsPayloadCodec for DepthPrepass with from_ecs_payload(payload) {
  match payload {
    EcsPayload_core_pipeline_prepass_DepthPrepass(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for NormalPrepass with to_ecs_payload(self) {
  EcsPayload_core_pipeline_prepass_NormalPrepass(self)
}

///|
pub impl @ecs.EcsPayloadCodec for NormalPrepass with from_ecs_payload(payload) {
  match payload {
    EcsPayload_core_pipeline_prepass_NormalPrepass(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for MotionVectorPrepass with to_ecs_payload(self) {
  EcsPayload_core_pipeline_prepass_MotionVectorPrepass(self)
}

///|
pub impl @ecs.EcsPayloadCodec for MotionVectorPrepass with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_core_pipeline_prepass_MotionVectorPrepass(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for PrepassViewState with to_ecs_payload(self) {
  EcsPayload_core_pipeline_prepass_PrepassViewState(self)
}

///|
pub impl @ecs.EcsPayloadCodec for PrepassViewState with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_core_pipeline_prepass_PrepassViewState(value) => Some(value)
    _ => None
  }
}
