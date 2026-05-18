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
  EcsPayload_pbr_deferred_DeferredPbrLightingState(DeferredPbrLightingState)
  EcsPayload_pbr_deferred_DeferredLightingPipeline(DeferredLightingPipeline)
  EcsPayload_pbr_deferred_PbrDeferredLightingDepthId(PbrDeferredLightingDepthId)
  EcsPayload_pbr_deferred_SkipDeferredLighting(SkipDeferredLighting)
}

///|
pub impl @ecs.EcsPayloadCodec for DeferredPbrLightingState with to_ecs_payload(
  self,
) {
  EcsPayload_pbr_deferred_DeferredPbrLightingState(self)
}

///|
pub impl @ecs.EcsPayloadCodec for DeferredPbrLightingState with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_pbr_deferred_DeferredPbrLightingState(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for DeferredLightingPipeline with to_ecs_payload(
  self,
) {
  EcsPayload_pbr_deferred_DeferredLightingPipeline(self)
}

///|
pub impl @ecs.EcsPayloadCodec for DeferredLightingPipeline with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_pbr_deferred_DeferredLightingPipeline(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for PbrDeferredLightingDepthId with to_ecs_payload(
  self,
) {
  EcsPayload_pbr_deferred_PbrDeferredLightingDepthId(self)
}

///|
pub impl @ecs.EcsPayloadCodec for PbrDeferredLightingDepthId with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_pbr_deferred_PbrDeferredLightingDepthId(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for SkipDeferredLighting with to_ecs_payload(self) {
  EcsPayload_pbr_deferred_SkipDeferredLighting(self)
}

///|
pub impl @ecs.EcsPayloadCodec for SkipDeferredLighting with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_pbr_deferred_SkipDeferredLighting(value) => Some(value)
    _ => None
  }
}
