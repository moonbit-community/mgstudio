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
  EcsPayload_core_pipeline_tonemapping_TonemappingLuts(TonemappingLuts)
  EcsPayload_core_pipeline_tonemapping_TonemappingPipelineKey(
    TonemappingPipelineKey
  )
}

///|
pub impl @ecs.EcsPayloadCodec for TonemappingLuts with to_ecs_payload(self) {
  EcsPayload_core_pipeline_tonemapping_TonemappingLuts(self)
}

///|
pub impl @ecs.EcsPayloadCodec for TonemappingLuts with from_ecs_payload(payload) {
  match payload {
    EcsPayload_core_pipeline_tonemapping_TonemappingLuts(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for TonemappingPipelineKey with to_ecs_payload(
  self,
) {
  EcsPayload_core_pipeline_tonemapping_TonemappingPipelineKey(self)
}

///|
pub impl @ecs.EcsPayloadCodec for TonemappingPipelineKey with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_core_pipeline_tonemapping_TonemappingPipelineKey(value) =>
      Some(value)
    _ => None
  }
}
