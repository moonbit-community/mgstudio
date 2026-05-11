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
  EcsPayload_pbr_light_probe_LightProbePluginState(LightProbePluginState)
  EcsPayload_pbr_light_probe_RenderViewLightProbes(RenderViewLightProbes)
  EcsPayload_pbr_light_probe_LightProbesUniform(LightProbesUniform)
  EcsPayload_pbr_light_probe_ViewLightProbesUniformOffset(
    ViewLightProbesUniformOffset
  )
}

///|
pub impl @ecs.EcsPayloadCodec for LightProbePluginState with to_ecs_payload(
  self,
) {
  EcsPayload_pbr_light_probe_LightProbePluginState(self)
}

///|
pub impl @ecs.EcsPayloadCodec for LightProbePluginState with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_pbr_light_probe_LightProbePluginState(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for RenderViewLightProbes with to_ecs_payload(
  self,
) {
  EcsPayload_pbr_light_probe_RenderViewLightProbes(self)
}

///|
pub impl @ecs.EcsPayloadCodec for RenderViewLightProbes with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_pbr_light_probe_RenderViewLightProbes(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for LightProbesUniform with to_ecs_payload(self) {
  EcsPayload_pbr_light_probe_LightProbesUniform(self)
}

///|
pub impl @ecs.EcsPayloadCodec for LightProbesUniform with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_pbr_light_probe_LightProbesUniform(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ViewLightProbesUniformOffset with to_ecs_payload(
  self,
) {
  EcsPayload_pbr_light_probe_ViewLightProbesUniformOffset(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ViewLightProbesUniformOffset with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_pbr_light_probe_ViewLightProbesUniformOffset(value) =>
      Some(value)
    _ => None
  }
}
