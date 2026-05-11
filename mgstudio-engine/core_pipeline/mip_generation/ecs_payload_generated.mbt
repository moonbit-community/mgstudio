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
  EcsPayload_core_pipeline_mip_generation_MipGenerationResources(
    MipGenerationResources
  )
  EcsPayload_core_pipeline_mip_generation_DownsampleShaders(DownsampleShaders)
  EcsPayload_core_pipeline_mip_generation_MipGenerationJobs(MipGenerationJobs)
  EcsPayload_core_pipeline_mip_generation_MipGenerationPipelines(
    MipGenerationPipelines
  )
}

///|
pub impl @ecs.EcsPayloadCodec for MipGenerationResources with to_ecs_payload(
  self,
) {
  EcsPayload_core_pipeline_mip_generation_MipGenerationResources(self)
}

///|
pub impl @ecs.EcsPayloadCodec for MipGenerationResources with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_core_pipeline_mip_generation_MipGenerationResources(value) =>
      Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for DownsampleShaders with to_ecs_payload(self) {
  EcsPayload_core_pipeline_mip_generation_DownsampleShaders(self)
}

///|
pub impl @ecs.EcsPayloadCodec for DownsampleShaders with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_core_pipeline_mip_generation_DownsampleShaders(value) =>
      Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for MipGenerationJobs with to_ecs_payload(self) {
  EcsPayload_core_pipeline_mip_generation_MipGenerationJobs(self)
}

///|
pub impl @ecs.EcsPayloadCodec for MipGenerationJobs with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_core_pipeline_mip_generation_MipGenerationJobs(value) =>
      Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for MipGenerationPipelines with to_ecs_payload(
  self,
) {
  EcsPayload_core_pipeline_mip_generation_MipGenerationPipelines(self)
}

///|
pub impl @ecs.EcsPayloadCodec for MipGenerationPipelines with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_core_pipeline_mip_generation_MipGenerationPipelines(value) =>
      Some(value)
    _ => None
  }
}
